///|
pub(open) trait LeafCommand: ToJson + @json.FromJson + Default {}

///|
priv type! ParseError {
  NoSubcommandFoundError
  NoSubcommandMatchError
  MissingArgumentError(String)
  UnknownArgumentError(String)
  DecodeError(@json.JsonDecodeError)
  InvalidCommandError
  NoPositionalFieldError
  PositionalIsNotArrayError
} derive(Show)

///|
struct CommandParser[T] {
  run : (ArrayView[String]) -> T!ParseError
}

///|
pub fn CommandParser::parse[T](
  self : CommandParser[T],
  args : Array[String]
) -> T {
  try {
    (self.run)!(args[:])
  } catch {
    e => {
      println(e)
      panic()
    }
  }
}

///|
pub fn CommandParser::parse_terminated[T](self : CommandParser[T]) -> T {
  try {
    (self.run)!(get_cli_args()[2:])
  } catch {
    e => {
      println(e)
      panic()
    }
  }
}

///|
pub fn leaf[T : LeafCommand]() -> CommandParser[T] {
  { run: fn(args) { parse_leaf!(args, T::default()) } }
}

///|
pub fn father[T](subs : Array[(String, CommandParser[T])]) -> CommandParser[T] {
  {
    run: fn(args) {
      if args.length() == 0 {
        raise NoSubcommandFoundError
      }
      let head = args[0]
      for pair in subs {
        let sub_name = pair.0
        let sub_parser = pair.1
        if head == sub_name {
          return (sub_parser.run)!(args[1:])
        }
      } else {
        raise NoSubcommandMatchError
      }
    },
  }
}

///|
pub fn unit() -> CommandParser[Unit] {
  { run: fn(_args) { return () } }
}

///|
pub fn CommandParser::map[Sub, T](
  self : CommandParser[Sub],
  builder : (Sub) -> T
) -> CommandParser[T] {
  { run: fn(args) { builder((self.run)!(args)) } }
}

///|
pub fn unit_map[T](builder : T) -> CommandParser[T] {
  { run: fn(_args) { builder } }
}

///|
fn parse_leaf[T : LeafCommand](
  argv : ArrayView[String],
  proto : T
) -> T!ParseError {
  let proto = proto.to_json().as_object().or_error!(InvalidCommandError)
  loop argv[:] {
    [x, .. xs] =>
      match proto[x] {
        Some(field) =>
          if field.as_bool() is Some(_) {
            proto[x] = Json::boolean(true)
            continue xs
          } else if field.as_string() is Some(_) {
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
          let positionals = proto["positionals"].or_error!(
            NoPositionalFieldError,
          )
          positionals
          .as_array()
          .or_error!(PositionalIsNotArrayError)
          .push(Json::string(x))
          continue xs
        }
      }
    [] => break
  }
  try {
    @json.from_json!(proto.to_json())
  } catch {
    e => raise DecodeError(e)
  }
}

///|
pub fn get_cli_args() -> Array[String] {
  @sys.get_cli_args()
}
