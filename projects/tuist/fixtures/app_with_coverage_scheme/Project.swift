import ProjectDescription

let coverageScheme = Scheme(
    name: "App-Coverage",
    shared: true,
    buildAction: BuildAction(
        targets: [
            TargetReference("App"),
            TargetReference("Framework1"),
            TargetReference("Framework2"),
        ], 
        preActions: []
    ),
    testAction: TestAction(
        targets: [
            TestableTarget(stringLiteral: "AppTests"),
            TestableTarget(stringLiteral: "Framework1Tests"),
            TestableTarget(stringLiteral: "Framework2Tests"),
        ],
        codeCoverageTargets: [
            TargetReference("AppTests"),
            TargetReference("Framework1Tests"),
            TargetReference("Framework2Tests"),
        ]
    ),
    archiveAction: nil
)

let project = Project(
    name: "AppWithCoverage",
    targets: [
        Target(name: "App",
               platform: .iOS,
               product: .app,
               bundleId: "io.tuist.App",
               infoPlist: .default,
               sources: "App/Sources/**",
               dependencies: [
                   .target(name: "Framework1"),
                   .target(name: "Framework2"),
               ]
        ),
        Target(name: "AppTests",
               platform: .iOS,
               product: .unitTests,
               bundleId: "io.tuist.AppTests",
               infoPlist: .default,
               sources: "App/Tests/**",
               dependencies: [.target(name: "App")]
        ),
        Target(name: "Framework1",
               platform: .iOS,
               product: .framework,
               bundleId: "io.tuist.Framework1",
               infoPlist: .default,
               sources: "Frameworks/Framework1/Sources/**",
               dependencies: [.target(name: "Framework2")]
        ),
        Target(name: "Framework1Tests",
               platform: .iOS,
               product: .unitTests,
               bundleId: "io.tuist.Framework1Tests",
               infoPlist: .default,
               sources: "Frameworks/Framework1/Tests/**",
               dependencies: [.target(name: "Framework2")]
        ),
        Target(name: "Framework2",
               platform: .iOS,
               product: .framework,
               bundleId: "io.tuist.Framework2",
               infoPlist: .default,
               sources: "Frameworks/Framework2/Sources/**"
        ),
        Target(name: "Framework2Tests",
               platform: .iOS,
               product: .unitTests,
               bundleId: "io.tuist.Framework2Tests",
               infoPlist: .default,
               sources: "Frameworks/Framework2/Tests/**"
        ),
    ],
    schemes: [
        coverageScheme
    ]
)
