import SwiftUI

struct MoviesPage: View {
    private let container: AppContainer
    @StateObject private var viewModel: MoviesViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(
            wrappedValue: MoviesViewModel(
                movieRepository: container.movieRepository,
                appStateRepository: container.appStateRepository
            )
        )
    }

    var body: some View {
        ThreeRegionPage(
            isFooterVisible: viewModel.isLoading || viewModel.errorMessage != nil,
            headerContent: {
                Text("Popular Movies").font(.title2).bold()
            },
            pageContent: {
                if viewModel.movies.isEmpty && viewModel.isLoading {
                    ProgressView("Loading movies…")
                } else {
                    List(Array(viewModel.movies.enumerated()), id: \.element.id) { index, movie in
                        NavigationLink(value: movie) {
                            MovieRow(movie: movie)
                        }
                        .task { await viewModel.loadNextPageIfNeeded(lastVisibleIndex: index) }
                    }
                }
            },
            footerContent: {
                HStack {
                    if viewModel.isLoading { ProgressView() }
                    Text(viewModel.errorMessage ?? "Loading page \(viewModel.currentPage + 1)…")
                    Spacer()
                    if viewModel.errorMessage != nil {
                        Button("Retry") { Task { await viewModel.retry() } }
                    }
                }
            }
        )
        .navigationDestination(for: Movie.self) { movie in
            MovieDetailsPage(movie: movie, container: container)
        }
        .task { await viewModel.loadInitialPage() }
    }
}

