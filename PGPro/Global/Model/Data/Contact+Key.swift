//
//  Contact+Key.swift
//  PGPro
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ObjectivePGP
import SwiftTryCatch

extension Contact {

    var key: Key {
        var keys = [Key(secretKey: nil, publicKey: nil)]

        // Hacky solution to recover from https://github.com/krzyzanowskim/ObjectivePGP/issues/168
        SwiftTryCatch.try({
            do {
                keys = try ObjectivePGP.readKeys(from: self.keyData as Data)
            } catch {
                Log.e(error)
            }
        }, catch: { (error) in
            Log.e("Error info: \(String(describing: error))")
            return
            }, finallyBlock: {
        })

        return keys[0]
    }

    var keyRequiresPassphrase: Bool {
        return key.isEncryptedWithPassword
    }

    var keyFingerprint: String? {
        if let pubKey = key.publicKey {
            return pubKey.fingerprint.description()
        } else if let privKey = key.secretKey {
            return privKey.fingerprint.description()
        } else {
            return nil
        }
    }

    var keySymbol: String {
        var symbol = "person.crop.circle.badge.questionmark" // invalid key

        if key.isPublic && !key.isSecret {
            symbol = "person.circle"
        } else if !key.isPublic && key.isSecret {
            symbol = "person.circle.fill"
        } else if key.isPublic && key.isSecret {
            symbol = "person.2.circle.fill"
        }

        return symbol
    }

    func getArmoredKey(as type: PGPKeyType) -> String? {
        switch type {
        case .public:
            do {
                let publicKeyData = try key.export(keyType: .public)
                return Armor.armored(publicKeyData, as: .publicKey)
            } catch { return nil }

        case .secret:
            do {
                let publicKeyData = try key.export(keyType: .public)
                let privateKeyData = try key.export(keyType: .secret)
                return Armor.armored(publicKeyData, as: .publicKey) + Armor.armored(privateKeyData, as: .secretKey)
            } catch { return nil }

        default:
            return nil
        }

    }

}
