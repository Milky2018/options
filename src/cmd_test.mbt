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
  let cmd : SimpleArg = @options.parse(argv[:])
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
  let cmd : CompilationCommand = parse(argv[:])
  let expected = { input: ["main.c", "lib.c"], output: "a.out", verbose: true }
  assert_eq!(cmd, expected)
}

///|
enum CloudCli {
  Build(BuildCommand)
  Deploy(DeployCommand)
  Run(RunCommand)
} derive(@json.FromJson, ToJson, Eq, Show)

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
  let argv = ["build", "./src", "--dist", "dist"]
  let cmd = SubcommandParser::new(argv[:])
    .subcommand("build", Build)
    .subcommand("run", Run)
    .subcommand("deploy", Deploy)
    .parse()
  assert_eq!(cmd, Build({ src: ["./src"], dist: "dist" }))
}
