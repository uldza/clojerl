-module('clojerl.IMeta').

-include("clojerl_int.hrl").

-clojure(true).
-protocol(true).

-export(['meta'/1, 'with_meta'/2]).
-export([?SATISFIES/1]).

-callback 'meta'(any()) -> any().
-callback 'with_meta'(any(), any()) -> any().

'meta'(X) ->
  case clj_rt:type_module(X) of
    'clojerl.Var' ->
      'clojerl.Var':'meta'(X);
    'clojerl.Atom' ->
      'clojerl.Atom':'meta'(X);
    'clojerl.Symbol' ->
      'clojerl.Symbol':'meta'(X);
    'clojerl.Namespace' ->
      'clojerl.Namespace':'meta'(X);
    'clojerl.LazySeq' ->
      'clojerl.LazySeq':'meta'(X);
    'clojerl.SortedMap' ->
      'clojerl.SortedMap':'meta'(X);
    'clojerl.Range' ->
      'clojerl.Range':'meta'(X);
    'clojerl.TupleMap' ->
      'clojerl.TupleMap':'meta'(X);
    'clojerl.Vector.RSeq' ->
      'clojerl.Vector.RSeq':'meta'(X);
    'clojerl.List' ->
      'clojerl.List':'meta'(X);
    'clojerl.Vector' ->
      'clojerl.Vector':'meta'(X);
    'clojerl.Map' ->
      'clojerl.Map':'meta'(X);
    'clojerl.Cons' ->
      'clojerl.Cons':'meta'(X);
    'clojerl.Vector.ChunkedSeq' ->
      'clojerl.Vector.ChunkedSeq':'meta'(X);
    'clojerl.Set' ->
      'clojerl.Set':'meta'(X);
    'clojerl.ChunkedCons' ->
      'clojerl.ChunkedCons':'meta'(X);
    'clojerl.SortedSet' ->
      'clojerl.SortedSet':'meta'(X);
    Type ->
      clj_protocol:not_implemented(?MODULE, 'meta', Type)
  end.

'with_meta'(X, Meta) ->
  case clj_rt:type_module(X) of
    'clojerl.Var' ->
      'clojerl.Var':'with_meta'(X, Meta);
    'clojerl.Atom' ->
      'clojerl.Atom':'with_meta'(X, Meta);
    'clojerl.Symbol' ->
      'clojerl.Symbol':'with_meta'(X, Meta);
    'clojerl.Namespace' ->
      'clojerl.Namespace':'with_meta'(X, Meta);
    'clojerl.LazySeq' ->
      'clojerl.LazySeq':'with_meta'(X, Meta);
    'clojerl.SortedMap' ->
      'clojerl.SortedMap':'with_meta'(X, Meta);
    'clojerl.Range' ->
      'clojerl.Range':'with_meta'(X, Meta);
    'clojerl.TupleMap' ->
      'clojerl.TupleMap':'with_meta'(X, Meta);
    'clojerl.Vector.RSeq' ->
      'clojerl.Vector.RSeq':'with_meta'(X, Meta);
    'clojerl.List' ->
      'clojerl.List':'with_meta'(X, Meta);
    'clojerl.Vector' ->
      'clojerl.Vector':'with_meta'(X, Meta);
    'clojerl.Map' ->
      'clojerl.Map':'with_meta'(X, Meta);
    'clojerl.Cons' ->
      'clojerl.Cons':'with_meta'(X, Meta);
    'clojerl.Vector.ChunkedSeq' ->
      'clojerl.Vector.ChunkedSeq':'with_meta'(X, Meta);
    'clojerl.Set' ->
      'clojerl.Set':'with_meta'(X, Meta);
    'clojerl.ChunkedCons' ->
      'clojerl.ChunkedCons':'with_meta'(X, Meta);
    'clojerl.SortedSet' ->
      'clojerl.SortedSet':'with_meta'(X, Meta);
    Type ->
      clj_protocol:not_implemented(?MODULE, 'with_meta', Type)
  end.

?SATISFIES('clojerl.Var') -> true;
?SATISFIES('clojerl.Atom') -> true;
?SATISFIES('clojerl.Symbol') -> true;
?SATISFIES('clojerl.Namespace') -> true;
?SATISFIES('clojerl.LazySeq') -> true;
?SATISFIES('clojerl.SortedMap') -> true;
?SATISFIES('clojerl.Range') -> true;
?SATISFIES('clojerl.TupleMap') -> true;
?SATISFIES('clojerl.Vector.RSeq') -> true;
?SATISFIES('clojerl.List') -> true;
?SATISFIES('clojerl.Vector') -> true;
?SATISFIES('clojerl.Map') -> true;
?SATISFIES('clojerl.Cons') -> true;
?SATISFIES('clojerl.Vector.ChunkedSeq') -> true;
?SATISFIES('clojerl.Set') -> true;
?SATISFIES('clojerl.ChunkedCons') -> true;
?SATISFIES('clojerl.SortedSet') -> true;
?SATISFIES(_) -> false.
