import Foundation

@MainActor
final class MoviesViewModel: ObservableObject {
    @Published private(set) var movies: [Movie] = []
    @Published private(set) var currentPage = 0
    @Published private(set) var totalPages = 1
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let movieRepository: MovieRepository
    private let appStateRepository: AppStateRepository

    init(movieRepository: MovieRepository, appStateRepository: AppStateRepository) {
        self.movieRepository = movieRepository
        self.appStateRepository = appStateRepository
    }

    func loadInitialPage() async {
        guard movies.isEmpty, !isLoading else { return }
        await loadPage(1)
    }

    func retry() async {
        let retryPage = currentPage == 0 ? 1 : currentPage + 1
        await loadPage(retryPage)
    }

    func loadNextPageIfNeeded(lastVisibleIndex: Int) async {
        guard MoviePolicies.shouldLoadNextPage(
            lastVisibleIndex: lastVisibleIndex,
            itemCount: movies.count,
            isLoading: isLoading,
            currentPage: currentPage,
            totalPages: totalPages
        ) else { return }
        await loadPage(currentPage + 1)
    }

    private func loadPage(_ pageNumber: Int) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            let page = try await movieRepository.popularMovies(pageNumber: pageNumber)
            movies = MoviePolicies.appendingUnique(existingMovies: movies, newMovies: page.movies)
            currentPage = page.pageNumber
            totalPages = page.totalPages
            var appState = appStateRepository.load()
            appState.lastSuccessfulPage = page.pageNumber
            appStateRepository.save(appState)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

