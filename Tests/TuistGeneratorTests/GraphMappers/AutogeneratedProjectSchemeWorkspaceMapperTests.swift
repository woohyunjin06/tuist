import Foundation
import TSCBasic
import TuistCore
import TuistGraph
import TuistGraphTesting
import XCTest

@testable import TuistGenerator
@testable import TuistSupportTesting

final class AutogeneratedProjectSchemeWorkspaceMapperTests: TuistUnitTestCase {
    func test_map() throws {
        // Given
        let subject = AutogeneratedProjectSchemeWorkspaceMapper(enableCodeCoverage: false)
        let targetA = Target.test(
            name: "A"
        )
        let targetATests = Target.test(
            name: "ATests",
            product: .unitTests,
            dependencies: [.target(name: "A")]
        )

        let projectPath = try temporaryPath()
        let project = Project.test(
            path: projectPath,
            targets: [
                targetA,
                targetATests,
            ]
        )

        let targetB = Target.test(
            name: "B"
        )
        let targetBTests = Target.test(
            name: "BTests",
            product: .unitTests,
            dependencies: [.target(name: "B")]
        )

        let projectBPath = try temporaryPath().appending(component: "ProjectB")
        let projectB = Project.test(
            path: projectBPath,
            targets: [
                targetB,
                targetBTests,
            ]
        )

        let workspace = Workspace.test(
            name: "A",
            projects: [
                project.path,
                projectB.path,
            ]
        )

        // When
        let (got, sideEffects) = try subject.map(
            workspace: WorkspaceWithProjects(workspace: workspace, projects: [project, projectB])
        )

        // Then
        XCTAssertEmpty(sideEffects)
        let schemes = got.workspace.schemes

        XCTAssertEqual(schemes.count, 1)
        let scheme = try XCTUnwrap(schemes.first)
        XCTAssertTrue(scheme.shared)
        XCTAssertEqual(scheme.name, "A-Project")
        XCTAssertEqual(
            Set(scheme.buildAction.map(\.targets) ?? []),
            Set([
                TargetReference(
                    projectPath: projectBPath,
                    name: targetB.name
                ),
                TargetReference(
                    projectPath: projectPath,
                    name: targetA.name
                ),
            ])
        )
        XCTAssertEqual(
            Set(scheme.testAction.map(\.targets) ?? []),
            Set([
                TestableTarget(
                    target: TargetReference(
                        projectPath: projectPath,
                        name: targetATests.name
                    )
                ),
                TestableTarget(
                    target: TargetReference(
                        projectPath: projectBPath,
                        name: targetBTests.name
                    )
                ),
            ])
        )
        XCTAssertFalse(try XCTUnwrap(scheme.testAction?.coverage))
    }

    func test_code_coverage_config() throws {
        // Given
        let subject = AutogeneratedProjectSchemeWorkspaceMapper(enableCodeCoverage: true)
        let targetA = Target.test(
            name: "A"
        )
        let targetATests = Target.test(
            name: "ATests",
            product: .unitTests,
            dependencies: [.target(name: "A")]
        )

        let projectPath = try temporaryPath()
        let project = Project.test(
            path: projectPath,
            targets: [
                targetA,
                targetATests,
            ]
        )

        let workspace = Workspace.test(
            name: "A",
            projects: [
                project.path,
            ]
        )

        // When
        let (got, sideEffects) = try subject.map(
            workspace: WorkspaceWithProjects(workspace: workspace, projects: [project])
        )

        // Then
        let scheme = try XCTUnwrap(got.workspace.schemes.first)
        XCTAssertTrue(try XCTUnwrap(scheme.testAction?.coverage))
    }

    func test_map_when_multiple_platforms() throws {
        // Given
        let subject = AutogeneratedProjectSchemeWorkspaceMapper(enableCodeCoverage: false)
        let targetA = Target.test(
            name: "A",
            platform: .iOS
        )
        let targetATests = Target.test(
            name: "ATests",
            platform: .iOS,
            product: .unitTests,
            dependencies: [.target(name: "A")]
        )

        let projectPath = try temporaryPath()
        let project = Project.test(
            path: projectPath,
            targets: [
                targetA,
                targetATests,
            ]
        )

        let targetB = Target.test(
            name: "B",
            platform: .macOS
        )
        let targetBTests = Target.test(
            name: "BTests",
            platform: .macOS,
            product: .unitTests,
            dependencies: [.target(name: "B")]
        )

        let projectBPath = try temporaryPath().appending(component: "ProjectB")
        let projectB = Project.test(
            path: projectBPath,
            targets: [
                targetB,
                targetBTests,
            ]
        )

        let workspace = Workspace.test(
            name: "A",
            projects: [
                project.path,
                projectB.path,
            ]
        )

        // When
        let (got, sideEffects) = try subject.map(
            workspace: WorkspaceWithProjects(workspace: workspace, projects: [project, projectB])
        )

        // Then
        XCTAssertEmpty(sideEffects)
        let schemes = got.workspace.schemes

        XCTAssertEqual(schemes.count, 2)
        XCTAssertEqual(
            Set(schemes.map(\.name)),
            Set([
                "A-Project-iOS",
                "A-Project-macOS",
            ])
        )
        let iosScheme = try XCTUnwrap(schemes.first(where: { $0.name == "A-Project-iOS" }))
        let macOSScheme = try XCTUnwrap(schemes.first(where: { $0.name == "A-Project-macOS" }))
        XCTAssertEqual(
            iosScheme.buildAction.map(\.targets) ?? [],
            [
                TargetReference(
                    projectPath: projectPath,
                    name: targetA.name
                ),
            ]
        )
        XCTAssertEqual(
            macOSScheme.buildAction.map(\.targets) ?? [],
            [
                TargetReference(
                    projectPath: projectBPath,
                    name: targetB.name
                ),
            ]
        )

        XCTAssertEqual(
            iosScheme.testAction.map(\.targets) ?? [],
            [
                TestableTarget(
                    target: TargetReference(
                        projectPath: projectPath,
                        name: targetATests.name
                    )
                ),
            ]
        )
        XCTAssertEqual(
            macOSScheme.testAction.map(\.targets) ?? [],
            [
                TestableTarget(
                    target: TargetReference(
                        projectPath: projectBPath,
                        name: targetBTests.name
                    )
                ),
            ]
        )
    }
}
