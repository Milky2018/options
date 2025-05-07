///|
test "Unit" {
  let cmd = @options.unit().parse([])
  assert_eq!(cmd, ())
}

///|
struct SimpleArg {
  name : String
} derive (
  @json.FromJson(fields(name(rename="--name"))),
  ToJson(fields(name(rename="--name"))),
  Default,
  Eq,
  Show,
)

///|
test "Simple argument" {
  let argv = ["--name", "Tom"]
  let cmd : SimpleArg = @options.leaf().parse(argv)
  assert_eq!(cmd, { name: "Tom" })
}

///|
struct CompilationCommand {
  input : Array[String]
  output : String
  verbose : Bool
} derive (
  @json.FromJson(
    fields(
      output(rename="--output"),
      input(rename="positionals"),
      verbose(rename="--verbose"),
    ),
  ),
  ToJson(
    fields(
      output(rename="--output"),
      input(rename="positionals"),
      verbose(rename="--verbose"),
    ),
  ),
  Default,
  Eq,
  Show,
)

///|
test "Compilation command" {
  let argv = ["main.c", "--output", "a.out", "--verbose", "lib.c"]
  let cmd : CompilationCommand = @options.leaf().parse(argv)
  let expected = { input: ["main.c", "lib.c"], output: "a.out", verbose: true }
  assert_eq!(cmd, expected)
}

///|
enum CloudCli {
  Build(BuildCommand)
  Deploy(DeployCommand)
  Run(RunCommand)
} derive(Eq, Show)

///|
struct BuildCommand {
  src : Array[String]
  dist : String
} derive (
  @json.FromJson(fields(src(rename="positionals"), dist(rename="--dist"))),
  ToJson(fields(src(rename="positionals"), dist(rename="--dist"))),
  Default,
  Eq,
  Show,
)

///|
struct DeployCommand {
  dist : String
  url : String
} derive (
  @json.FromJson(fields(url(rename="--url"), dist(rename="--dist"))),
  ToJson(fields(url(rename="--url"), dist(rename="--dist"))),
  Default,
  Eq,
  Show,
)

///|
struct RunCommand {
  url : String
} derive (
  @json.FromJson(fields(url(rename="--url"))),
  ToJson(fields(url(rename="--url"))),
  Default,
  Eq,
  Show,
)

///|
test "Cloud CLI" {
  let parser = @options.father([
    ("build", @options.leaf().map(Build)),
    ("deploy", @options.leaf().map(Deploy)),
    ("run", @options.leaf().map(Run)),
  ])
  let argv1 = ["build", "./src", "--dist", "dist"]
  assert_eq!(parser.parse(argv1), Build({ src: ["./src"], dist: "dist" }))
  let argv2 = ["deploy", "--dist", "dist", "--url", "localhost:3000"]
  assert_eq!(
    parser.parse(argv2),
    Deploy({ dist: "dist", url: "localhost:3000" }),
  )
}

///|
enum ResourceCommand {
  Pod(PodCommand)
  Node(NodeCommand)
  Service(ServiceCommand)
} derive(Eq, Show)

///|
enum PodCommand {
  List
  Create
  Delete
} derive(Eq, Show)

///|
enum NodeCommand {
  List
  Create
  Delete
} derive(Eq, Show)

///|
enum ServiceCommand {
  List
  Create
  Delete
} derive(Eq, Show)

///|
test "Nested subcommands" {
  let parser = @options.father([
    (
      "pod",
      @options.father([
        ("list", @options.unit_map(PodCommand::List)),
        ("create", @options.unit_map(PodCommand::Create)),
        ("delete", @options.unit_map(PodCommand::Delete)),
      ]).map(Pod),
    ),
    (
      "node",
      @options.father([
        ("list", @options.unit_map(NodeCommand::List)),
        ("create", @options.unit_map(NodeCommand::Create)),
        ("delete", @options.unit_map(NodeCommand::Delete)),
      ]).map(Node),
    ),
    (
      "service",
      @options.father([
        ("list", @options.unit_map(ServiceCommand::List)),
        ("create", @options.unit_map(ServiceCommand::Create)),
        ("delete", @options.unit_map(ServiceCommand::Delete)),
      ]).map(Service),
    ),
  ])
  let argv = ["pod", "list"]
  assert_eq!(parser.parse(argv), Pod(PodCommand::List))
}
