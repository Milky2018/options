///|
pub(open) trait LeafCommand: ToJson + @json.FromJson + Default {}

///|
priv suberror ParseError {
  NoSubcommandFoundError
  NoSubcommandMatchError
  MissingArgumentError(String)
  UnknownArgumentError(String)
  DecodeError(@json.JsonDecodeError)
  InvalidCommandError
  NoPositionalFieldError
  PositionalIsNotArrayError
} derive(Debug)

///|
struct CommandParser[T] {
  run : (ArrayView[String]) -> T raise ParseError
}

///|
pub fn[T] CommandParser::parse(
  self : CommandParser[T],
  args : Array[String],
) -> T {
  (self.run)(args[:]) catch {
    e => {
      println(Repr(e))
      panic()
    }
  }
}

///|
pub fn[T] CommandParser::parse_terminated(self : CommandParser[T]) -> T {
  (self.run)(get_cli_args()[2:]) catch {
    e => {
      println(Repr(e))
      panic()
    }
  }
}

///|
pub fn[T : LeafCommand] leaf() -> CommandParser[T] {
  { run: args => parse_leaf(args, Default::default()), }
}

///|
pub fn[T] father(subs : Array[(String, CommandParser[T])]) -> CommandParser[T] {
  {
    run: args => {
      if args.length() == 0 {
        raise NoSubcommandFoundError
      }
      let head = args[0]
      for pair in subs {
        let sub_name = pair.0
        let sub_parser = pair.1
        if head == sub_name {
          return (sub_parser.run)(args[1:])
        }
      } nobreak {
        raise NoSubcommandMatchError
      }
    },
  }
}

///|
pub fn unit() -> CommandParser[Unit] {
  { run: fn(_args) { return () }, }
}

///|
pub fn[Sub, T] CommandParser::map(
  self : CommandParser[Sub],
  builder : (Sub) -> T,
) -> CommandParser[T] {
  { run: args => builder((self.run)(args)), }
}

///|
pub fn[T] unit_map(builder : T) -> CommandParser[T] {
  { run: fn(_args) { builder }, }
}

///|
fn[T : LeafCommand] parse_leaf(
  argv : ArrayView[String],
  proto : T,
) -> T raise ParseError {
  guard ToJson::to_json(proto) is Object(proto) else {
    raise InvalidCommandError
  }
  for args = argv {
    match args {
      [x, .. xs] =>
        match proto.get(x) {
          Some(field) =>
            if field is (True | False) {
              proto[x] = Json::boolean(true)
              continue xs
            } else if field is String(_) {
              match xs {
                [y, .. ys] => {
                  proto[x] = Json::string(y)
                  continue ys
                }
                _ => raise MissingArgumentError(x)
              }
            } else {
              raise UnknownArgumentError(x)
            }
          None => {
            let positionals = proto
              .get("positionals")
              .unwrap_or_else(() => raise NoPositionalFieldError)
            guard positionals is Array(values) else {
              raise PositionalIsNotArrayError
            }
            values.push(Json::string(x))
            continue xs
          }
        }
      [] => break
    }
  }
  @json.from_json(ToJson::to_json(proto)) catch {
    e => raise DecodeError(e)
  }
}

///|
#cfg(not(target="js"))
pub fn get_cli_args() -> Array[String] {
  @env.args()
}

///|
#cfg(target="js")
pub fn get_cli_args() -> Array[String] {
  @env.args()[1:].to_array()
}
