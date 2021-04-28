import Foundation
import TSCBasic
import TuistGraph
import TuistSupport

public protocol XcodeBuildLocating {

    /// Locates the build output directory for `xcodebuild` command.
    ///
    /// - Parameters:
    ///   - platform: The platform for the built scheme.
    ///   - projectPath: The path of the Xcode project or workspace.
    ///   - configuration: The configuration name, i.e. `Release`, `Debug`, or something custom.
    func locateBuildDirectory(
        platform: Platform,
        projectPath: AbsolutePath,
        configuration: String
    ) throws -> AbsolutePath

    /// Locates the products output directory for `xcodebuild` command.
    ///
    /// - Parameters:
    ///   - projectPath: The path of the Xcode project or workspace.
    func locateProductsDirectory(for projectPath: AbsolutePath) throws -> AbsolutePath
}

public enum XcodeBuildLocatorError: FatalError {
    case sdkNotFound(platform: String)

    public var type: ErrorType {
        switch self {
        case .sdkNotFound:
            return .bug
        }
    }

    public var description: String {
        switch self {
        case let .sdkNotFound(platform):
            return "Unable to find SDK for platform \(platform)"
        }
    }
}

public final class XcodeBuildLocator: XcodeBuildLocating {
    private let derivedDataLocator: DerivedDataLocating

    public init(derivedDataLocator: DerivedDataLocating = DerivedDataLocator()) {
        self.derivedDataLocator = derivedDataLocator
    }

    public func locateBuildDirectory(
        platform: Platform,
        projectPath: AbsolutePath,
        configuration: String
    ) throws -> AbsolutePath {
        let configSDKPathComponent: String = try {
            if platform == .macOS {
                return configuration
            } else {
                guard let sdk = platform.xcodeSimulatorSDK else {
                    throw XcodeBuildLocatorError.sdkNotFound(platform: platform.rawValue)
                }
                return "\(configuration)-\(sdk)"
            }
        }()

        return try locateProductsDirectory(for: projectPath)
            .appending(component: configSDKPathComponent)
    }

    public func locateProductsDirectory(for projectPath: AbsolutePath) throws -> AbsolutePath {
        return try derivedDataLocator.locate(for: projectPath)
            .appending(component: "Build")
            .appending(component: "Products")
    }
}
