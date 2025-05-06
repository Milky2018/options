///|
test "Hello" {
  println("Hello")
}

///|
pub(all) enum Flag {
  String(Ref[String])
  Bool(Ref[Bool])
}

///|
struct Command {
  flags : Map[String, Flag]
  subcommands : Map[String, Command]
}

///|
pub fn Command::new() -> Command {
  Command::{ flags: {}, subcommands: {} }
}

///|
pub fn with_flag(self : Command, name : String, flag : Flag) -> Command {
  self.flags[name] = flag
  self
}

pub fn with_subcommand(self : Command, name : String, subcommand : Command) -> Command {
  self.subcommands[name] = subcommand
  self
}

///|
pub fn parse(self : Command, argv : Array[String]) -> Array[String] {
  let rest = []
  loop argv[:] {
    [] => ()
    [x, .. xs] =>
      match self.flags[x] {
        None => {
          rest.push(x)
          continue xs
        }
        Some(setter) =>
          match (setter, xs) {
            (String(s), [y, .. ys]) => {
              if self.flags[y] is Some(_) {
                println("Warning: argument value \{y} is also a valid argument name.")
              }
              s.val = y
              continue ys
            }
            (String(_), []) => println("Missing argument for \{x}")
            (Bool(b), _) => {
              b.val = true
              continue xs
            }
          }
      }
  }
  rest
}

///|

///|
test "Basic simple option" {
  struct SimpleOption {
    name : Flag
    age : Flag
  }

  let argv = ["--name", "Tom", "--age", "18"]
  let opt = { name: String(@ref.new("")), age: String(@ref.new("")) }
  let parser = Command::new()
    .with_flag("--name", opt.name)
    .with_flag("--age", opt.age)
  let _rest_args = parser.parse(argv)
  match opt.name {
    String({ val }) => assert_eq!(val, "Tom")
    Bool(_) => panic()
  }
}

test "Getting rest arguments" {

}