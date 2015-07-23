-module(clj_reader).

-export([read/1, read_all/1]).

-type attrs() :: #{}.
-type ast_node() :: #{type => atom,
                      attrs => attrs(),
                      children => [atom()]}.

-type state() :: #{src => binary(),
                   forms => [ast_node()]}.

-type char_type() :: whitespace | number | string
                   | keyword | comment | quote
                   | deref | meta | syntax_quote
                   | unquote | list | vector
                   | map | unmatched_delim | char
                   | unmatched_delim | char
                   | arg | dispatch | symbol.

-spec read(binary()) -> ast_node().
read(Src) ->
  State = #{src => Src, forms => []},
  #{forms := Forms} = dispatch(State),
  hd(Forms).

-spec read_all(state()) -> [ast_node()].
read_all(Src) ->
  State = #{src => Src,
            forms => [],
            all => true},
  #{forms := Forms} = dispatch(State),
  lists:reverse(Forms).

-spec dispatch(state()) -> state().
dispatch(#{src := <<>>} = State) ->
  State;
dispatch(#{src := Src} = State) ->
  <<First, Rest/binary>> = Src,
  NewState = case char_type(First, Rest) of
               whitespace -> dispatch(State#{src => Rest});
               number -> read_number(State);
               string -> read_string(State);
               keyword -> read_keyword(State);
               comment -> read_comment(State);
               quote -> read_quote(State);
               deref -> read_deref(State);
               meta -> read_meta(State);
               syntax_quote -> read_syntax_quote(State);
               unquote -> read_unquote(State);
               list -> read_list(State);
               vector -> read_vector(State);
               map -> read_map(State);
               unmatched_delim -> read_unmatched_delim(State);
               char -> read_char(State);
               arg -> read_arg(State);
               dispatch -> read_dispatch(State);
               symbol -> read_symbol(State)
             end,
  next(NewState).

-spec next(state()) -> state().
next(#{all := true} = State) -> dispatch(State);
next(State) -> State.

-spec char_type(non_neg_integer(), binary()) -> char_type().
char_type(X, _)
  when X == $\n; X == $\t; X == $\r; X == $ ; X == $,->
  whitespace;
char_type(X, _)
  when X >= $0, X =< $9 ->
  number;
char_type(X, <<Y, _/binary>>)
  when (X == $+ orelse X == $-),
       Y >= $0, Y =< $9 ->
  number;
char_type($", _) -> string;
char_type($:, _) -> keyword;
char_type($;, _) -> comment;
char_type($', _) -> quote;
char_type($@, _) -> deref;
char_type($^, _) -> meta;
char_type($`, _) -> syntax_quote;
char_type($~, _) -> unquote;
char_type($(, _) -> list;
char_type($[, _) -> vector;
char_type(${, _) -> map;
char_type(X, _)
  when X == $); X == $]; X == $} ->
  unmatched_delim;
char_type($\\, _) -> char;
char_type($%, _) -> arg;
char_type($#, _) -> dispatch;
char_type(_, _) -> symbol.

-spec read_number(state()) -> state().
read_number(#{forms := Forms, src := Src} = State) ->
  {SrcRest, Current} = consume(Src, [number, symbol]),
  Number = clj_utils:parse_number(Current),
  State#{forms => [Number | Forms],
         src   => SrcRest}.

-spec read_string(state()) -> state().
read_string(#{forms := Forms,
              src := <<"\"", SrcRest/binary>>,
              current := String} = State0) ->
  State = maps:remove(current, State0),
  State#{forms => [String | Forms],
         src => SrcRest};
read_string(#{src := <<"\\", SrcRest/binary>>,
              current := String} = State0) ->
  {EscapedChar, Rest} = escape_char(SrcRest),
  State = State0#{current => <<String/binary,
                               EscapedChar/binary>>,
                  src => Rest},
  read_string(State);
read_string(#{src := <<Char, SrcRest/binary>>,
              current := String} = State0) ->
  State = State0#{current => <<String/binary, Char>>,
                  src => SrcRest},
  read_string(State);
read_string(#{src := <<"\"", Rest/binary>>} = State) ->
  read_string(State#{src => Rest, current => <<>>});
read_string(#{src := <<>>}) ->
  throw(<<"EOF while reading string">>).

-spec escape_char(binary()) -> {binary(), binary()}.
escape_char(<<Char, Rest/binary>>) ->
  Escaped =
    case Char of
      $t -> <<"\t">>;
      $r -> <<"\r">>;
      $n -> <<"\n">>;
      $\ -> <<"\\">>;
      $" -> <<"\"">>;
      $b -> <<"\b">>;
      $f -> <<"\f">>;
      $u -> <<"unicode">>
    end,
  {Escaped, Rest}.

read_keyword(_) -> keyword.

read_comment(_) -> comment.

read_quote(_) -> quote.

read_deref(#{forms := Forms,
             src := <<_, Src/binary>>} = State) ->
  State#{forms => [deref | Forms],
         src => Src}.

read_meta(_) -> meta.

read_syntax_quote(_) -> syntax_quote.

read_unquote(_) -> unquote.

read_list(_) -> list.

read_vector(_) -> vector.

read_map(_) -> map.

read_unmatched_delim(_) -> throw(unmatched_delim).

read_char(_) -> char.

read_arg(_) -> arg.

read_dispatch(_) -> dispatch.

read_symbol(_) -> symbol.

-spec consume(binary(), [char_type()]) -> {binary(), binary()}.
consume(Src, Types) ->
  do_consume(Src, <<>>, Types).

do_consume(<<>>, Acc, _Types) ->
  {<<>>, Acc};
do_consume(<<X, Rest/binary>> = Src, Acc, Types) ->
  Type = char_type(X, Rest),
  case lists:member(Type, Types) of
    true -> do_consume(Rest, <<Acc/binary, X>>, Types);
    false -> {Src, Acc}
  end.
