///|
pub(open) trait LeafCommand: ToJson + @json.FromJson + Default {}

///|
struct CommandParser[T] {
  run : (ArrayView[String]) -> T
}

///|
pub fn CommandParser::parse[T](
  self : CommandParser[T],
  args : Array[String]
) -> T {
  (self.run)(args[:])
}

///|
pub fn leaf[T : LeafCommand]() -> CommandParser[T] {
  { run: fn(args) { parse_leaf(args, T::default()) } }
}

///|
pub fn father[T](subs : Array[(String, CommandParser[T])]) -> CommandParser[T] {
  {
    run: fn(args) {
      for pair in subs {
        let sub_name = pair.0
        let sub_parser = pair.1
        let head = args[0]
        if head == sub_name {
          return (sub_parser.run)(args[1:])
        }
      } else {
        panic()
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
  { run: fn(args) { builder((self.run)(args)) } }
}

///|
pub fn unit_map[T](builder : T) -> CommandParser[T] {
  { run: fn(_args) { builder } }
}

///|
fn parse_leaf[T : LeafCommand](argv : ArrayView[String], proto : T) -> T {
  let proto = proto.to_json().as_object().unwrap()
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
              _ => panic()
            }
          } else {
            panic()
          }
        None => {
          let positionals = proto["positionals"].unwrap()
          positionals.as_array().unwrap().push(Json::string(x))
          continue xs
        }
      }
    [] => break
  }
  try {
    @json.from_json!(proto.to_json())
  } catch {
    _ => panic()
  }
}
