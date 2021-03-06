-module('clojerl.ILookup').

-include("clojerl_int.hrl").

-clojure(true).
-protocol(true).

-export(['get'/2, 'get'/3]).
-export([?SATISFIES/1]).

-callback 'get'(any(), any()) -> any().
-callback 'get'(any(), any(), any()) -> any().

'get'(X, Key) ->
  case clj_rt:type_module(X) of
    'erlang.Map' ->
      'erlang.Map':'get'(X, Key);
    'erlang.List' ->
      'erlang.List':'get'(X, Key);
    'clojerl.reader.TaggedLiteral' ->
      'clojerl.reader.TaggedLiteral':'get'(X, Key);
    'clojerl.reader.ReaderConditional' ->
      'clojerl.reader.ReaderConditional':'get'(X, Key);
    'clojerl.SortedMap' ->
      'clojerl.SortedMap':'get'(X, Key);
    'clojerl.TupleMap' ->
      'clojerl.TupleMap':'get'(X, Key);
    'clojerl.Vector' ->
      'clojerl.Vector':'get'(X, Key);
    'clojerl.Map' ->
      'clojerl.Map':'get'(X, Key);
    'clojerl.Set' ->
      'clojerl.Set':'get'(X, Key);
    'clojerl.SortedSet' ->
      'clojerl.SortedSet':'get'(X, Key);
    Type ->
      clj_protocol:not_implemented(?MODULE, 'get', Type)
  end.

'get'(X, Key, NotFound) ->
  case clj_rt:type_module(X) of
    'erlang.Map' ->
      'erlang.Map':'get'(X, Key, NotFound);
    'erlang.List' ->
      'erlang.List':'get'(X, Key, NotFound);
    'clojerl.reader.TaggedLiteral' ->
      'clojerl.reader.TaggedLiteral':'get'(X, Key, NotFound);
    'clojerl.reader.ReaderConditional' ->
      'clojerl.reader.ReaderConditional':'get'(X, Key, NotFound);
    'clojerl.SortedMap' ->
      'clojerl.SortedMap':'get'(X, Key, NotFound);
    'clojerl.TupleMap' ->
      'clojerl.TupleMap':'get'(X, Key, NotFound);
    'clojerl.Vector' ->
      'clojerl.Vector':'get'(X, Key, NotFound);
    'clojerl.Map' ->
      'clojerl.Map':'get'(X, Key, NotFound);
    'clojerl.Set' ->
      'clojerl.Set':'get'(X, Key, NotFound);
    'clojerl.SortedSet' ->
      'clojerl.SortedSet':'get'(X, Key, NotFound);
    Type ->
      clj_protocol:not_implemented(?MODULE, 'get', Type)
  end.

?SATISFIES('erlang.Map') -> true;
?SATISFIES('erlang.List') -> true;
?SATISFIES('clojerl.reader.TaggedLiteral') -> true;
?SATISFIES('clojerl.reader.ReaderConditional') -> true;
?SATISFIES('clojerl.SortedMap') -> true;
?SATISFIES('clojerl.TupleMap') -> true;
?SATISFIES('clojerl.Vector') -> true;
?SATISFIES('clojerl.Map') -> true;
?SATISFIES('clojerl.Set') -> true;
?SATISFIES('clojerl.SortedSet') -> true;
?SATISFIES(_) -> false.
