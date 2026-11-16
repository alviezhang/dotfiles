import Foundation
import Security

// keychainAccessGroup is defined in kc-config.swift, injected at compile time:
//   let keychainAccessGroup: String? = "TEAMID.bundle.id"  (sync enabled)

// dotfiles-keychain <get|set|delete> <service> <account>
// The set command reads the password from stdin.
// Exit: 0 = ok, 44 = not found (matches security(1)), 1 = error

@main
struct KeychainHelper {
    static func main() {
        let args = CommandLine.arguments
        guard args.count >= 4 else {
            fputs("Usage: dotfiles-keychain <get|set|delete> <service> <account>\n", stderr)
            exit(1)
        }
        let cmd     = args[1]
        let service = args[2]
        let account = args[3]

        switch cmd {
        case "get":    get(service: service, account: account)
        case "set":
            // Read password from stdin to avoid argv exposure via ps/sysctl
            guard let password = readLine(strippingNewline: true), !password.isEmpty else {
                fputs("error: password must be provided on stdin\n", stderr)
                exit(1)
            }
            set(service: service, account: account, password: password)
        case "delete": delete(service: service, account: account)
        default:
            fputs("Unknown command: \(cmd)\n", stderr)
            exit(1)
        }
    }

    static func makeQuery(service: String, account: String, synchronizable: Any) -> [String: Any] {
        var q: [String: Any] = [
            kSecClass as String:              kSecClassGenericPassword,
            kSecAttrService as String:        service,
            kSecAttrAccount as String:        account,
            kSecAttrSynchronizable as String: synchronizable,
        ]
        if let group = keychainAccessGroup {
            q[kSecAttrAccessGroup as String] = group
        }
        return q
    }

    static func get(service: String, account: String) {
        var query = makeQuery(service: service, account: account,
                              synchronizable: kSecAttrSynchronizableAny)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { exit(44) }
        guard status == errSecSuccess else {
            fputs("error: SecItemCopyMatching status \(status)\n", stderr)
            exit(1)
        }
        guard let data = item as? Data, let pw = String(data: data, encoding: .utf8) else {
            fputs("error: Keychain data is missing or not valid UTF-8\n", stderr)
            exit(1)
        }
        print(pw, terminator: "")
    }

    static func set(service: String, account: String, password: String) {
        guard let data = password.data(using: .utf8) else {
            fputs("error: password is not valid UTF-8\n", stderr)
            exit(1)
        }
        let synced = keychainAccessGroup != nil
        let syncFlag: Any = synced ? kCFBooleanTrue as Any : kCFBooleanFalse as Any
        let target = makeQuery(service: service, account: account, synchronizable: syncFlag)

        // Update in place, add only when missing: a failed write never removes the
        // existing passphrase (a deletion would also propagate via iCloud Keychain).
        var status = SecItemUpdate(target as CFDictionary,
                                   [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = target
            addQuery[kSecValueData as String] = data
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }
        guard status == errSecSuccess else {
            fputs("error: writing Keychain item failed with status \(status); existing item left unchanged\n", stderr)
            exit(1)
        }

        // Migration: remove a same-named item with the opposite sync state (e.g. one
        // created by `security add-generic-password`). Runs only after the new value
        // is stored; failure here does not affect it.
        let legacyQuery: [String: Any] = [
            kSecClass as String:              kSecClassGenericPassword,
            kSecAttrService as String:        service,
            kSecAttrAccount as String:        account,
            kSecAttrSynchronizable as String: synced ? kCFBooleanFalse as Any : kCFBooleanTrue as Any,
        ]
        let legacy = SecItemDelete(legacyQuery as CFDictionary)
        if legacy != errSecSuccess && legacy != errSecItemNotFound {
            fputs("warning: could not remove legacy Keychain item (status \(legacy)); new value is stored\n", stderr)
        }
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String:              kSecClassGenericPassword,
            kSecAttrService as String:        service,
            kSecAttrAccount as String:        account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            fputs("error: SecItemDelete status \(status)\n", stderr)
            exit(1)
        }
    }
}
