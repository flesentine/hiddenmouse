import Foundation

struct RemoteContentPackage: Equatable, Sendable {
    let revision: Int
    let catalogData: Data
    let signature: Data

    init(
        revision: Int,
        catalogData: Data,
        signature: Data
    ) {
        self.revision = revision
        self.catalogData = catalogData
        self.signature = signature
    }
}

protocol RemoteContentFetching: AnyObject {
    var isAvailable: Bool { get }
    func fetchLatest() throws -> RemoteContentPackage?
}

protocol RemoteContentVerifying: AnyObject {
    func isTrusted(_ package: RemoteContentPackage) -> Bool
}

final class NoopRemoteContentFetcher: RemoteContentFetching {
    var isAvailable: Bool { false }

    func fetchLatest() throws -> RemoteContentPackage? {
        nil
    }
}

final class RejectingRemoteContentVerifier: RemoteContentVerifying {
    func isTrusted(_ package: RemoteContentPackage) -> Bool {
        false
    }
}

final class MemoryRemoteContentFetcher: RemoteContentFetching {
    var isAvailable: Bool
    var package: RemoteContentPackage?

    init(
        package: RemoteContentPackage? = nil,
        isAvailable: Bool = true
    ) {
        self.package = package
        self.isAvailable = isAvailable
    }

    func fetchLatest() throws -> RemoteContentPackage? {
        package
    }
}

final class MemoryRemoteContentVerifier: RemoteContentVerifying {
    var trustedRevisions: Set<Int>

    init(trustedRevisions: Set<Int> = []) {
        self.trustedRevisions = trustedRevisions
    }

    func isTrusted(_ package: RemoteContentPackage) -> Bool {
        trustedRevisions.contains(package.revision)
    }
}

enum RemoteContentSelection: Equatable, Sendable {
    case bundled
    case remote(revision: Int)
}

final class RemoteFallbackContentSource: ContentCatalogSource {
    private let bundled: any ContentCatalogSource
    private let fetcher: any RemoteContentFetching
    private let verifier: any RemoteContentVerifying
    private let minimumRevision: Int
    private let revealImageExists: (String) -> Bool

    private(set) var selection: RemoteContentSelection = .bundled

    init(
        bundled: any ContentCatalogSource,
        fetcher: any RemoteContentFetching,
        verifier: any RemoteContentVerifying,
        minimumRevision: Int = 1,
        revealImageExists: @escaping (String) -> Bool = {
            BundledRevealImageStore().containsImage(named: $0)
        }
    ) {
        self.bundled = bundled
        self.fetcher = fetcher
        self.verifier = verifier
        self.minimumRevision = minimumRevision
        self.revealImageExists = revealImageExists
    }

    func loadCatalog() throws -> ContentCatalog {
        guard fetcher.isAvailable,
              let package = try? fetcher.fetchLatest(),
              package.revision >= minimumRevision,
              verifier.isTrusted(package),
              let catalog = try? ContentCatalogCodec.decode(
                package.catalogData
              ),
              ContentCatalogValidator.validate(catalog).isEmpty else {
            selection = .bundled
            return try bundled.loadCatalog()
        }

        let snapshot = ContentSnapshot(catalog: catalog)
        let offlineIssues = OfflineReadinessValidator.validate(
            snapshot: snapshot,
            imageExists: revealImageExists
        )

        guard offlineIssues.isEmpty else {
            selection = .bundled
            return try bundled.loadCatalog()
        }

        selection = .remote(revision: package.revision)
        return catalog
    }
}

enum RemoteContentStatus: Equatable, Sendable {
    case unavailable
    case bundled
    case remote(revision: Int)
}

protocol RemoteContentServicing: AnyObject {
    func status() -> RemoteContentStatus
    func refresh() -> RemoteContentStatus
}

final class RemoteContentService: RemoteContentServicing {
    private let loader: ContentLoader
    private let source: RemoteFallbackContentSource
    private let fetcher: any RemoteContentFetching

    init(
        loader: ContentLoader,
        source: RemoteFallbackContentSource,
        fetcher: any RemoteContentFetching
    ) {
        self.loader = loader
        self.source = source
        self.fetcher = fetcher
    }

    func status() -> RemoteContentStatus {
        guard fetcher.isAvailable else {
            return .unavailable
        }

        switch source.selection {
        case .bundled:
            return .bundled
        case let .remote(revision):
            return .remote(revision: revision)
        }
    }

    func refresh() -> RemoteContentStatus {
        guard fetcher.isAvailable else {
            return .unavailable
        }

        _ = try? loader.reload()
        return status()
    }
}

enum RemoteContentFactory {
    static func makeProduction() -> (
        loader: ContentLoader,
        service: any RemoteContentServicing
    ) {
        let fetcher = NoopRemoteContentFetcher()
        let source = RemoteFallbackContentSource(
            bundled: BundledContentStore(),
            fetcher: fetcher,
            verifier: RejectingRemoteContentVerifier()
        )
        let loader = ContentLoader(source: source)
        let service = RemoteContentService(
            loader: loader,
            source: source,
            fetcher: fetcher
        )
        return (loader, service)
    }
}
