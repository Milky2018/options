///|
pub(open) trait Command: @json.FromJson + ToJson + Default {}

///|
pub fn parse[T : Command](argv : ArrayView[String]) -> T {
  let proto = T::default().to_json().as_object().unwrap()
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

///|
pub(open) trait RootCommand: @json.FromJson + ToJson {}

///|
struct SubcommandParser[T] {
  argv : ArrayView[String]
  mut possible : T?
}

///|
pub fn SubcommandParser::new[T : RootCommand](
  argv : ArrayView[String]
) -> SubcommandParser[T] {
  { argv, possible: None }
}

///|
pub fn subcommand[S : Command, T : RootCommand](
  self : SubcommandParser[T],
  cmd : String,
  builder : (S) -> T
) -> SubcommandParser[T] {
  match self.argv {
    [x, .. xs] =>
      if cmd == x.to_string() {
        let s = parse(xs)
        self.possible = Some(builder(s))
        self
      } else {
        self
      }
    [] => self
  }
}

///|
pub fn SubcommandParser::parse[T](self : SubcommandParser[T]) -> T {
  self.possible.unwrap()
}
