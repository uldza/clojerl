-module('clojerl.Var').

-include("clojerl.hrl").
-include("clojerl_int.hrl").

-behavior('clojerl.IDeref').
-behavior('clojerl.IEquiv').
-behavior('clojerl.IFn').
-behavior('clojerl.IHash').
-behavior('clojerl.IMeta').
-behavior('clojerl.INamed').
-behavior('clojerl.IStringable').

-export([ ?CONSTRUCTOR/2
        , is_dynamic/1
        , is_macro/1
        , is_public/1
        , is_bound/1
        , has_root/1
        , get/1
        ]).

-export([ function/1
        , module/1
        , val_function/1
        , process_args/3
        , mark_fake_fun/1
        ]).

-export([ push_bindings/1
        , pop_bindings/0
        , get_bindings/0
        , get_bindings_map/0
        , reset_bindings/1
        , dynamic_binding/1
        , dynamic_binding/2
        , find/1
        ]).

-export([deref/1]).
-export([equiv/2]).
-export([apply/2]).
-export([hash/1]).
-export([ meta/1
        , with_meta/2
        ]).
-export([ name/1
        , namespace/1
        ]).
-export([str/1]).

-type type() :: #{ ?TYPE     => ?M
                 , ns        => binary()
                 , name      => binary()
                 , ns_atom   => atom()
                 , name_atom => atom()
                 , val_atom  => atom()
                 , meta      => ?NIL | any()
                 , fake_fun  => boolean()
                 }.

-spec ?CONSTRUCTOR(binary(), binary()) -> type().
?CONSTRUCTOR(Ns, Name) ->
  #{ ?TYPE     => ?M
   , ns        => Ns
   , name      => Name
   , ns_atom   => binary_to_atom(Ns, utf8)
   , name_atom => binary_to_atom(Name, utf8)
   , val_atom  => binary_to_atom(<<Name/binary, "__val">>, utf8)
   , meta      => ?NIL
   , fake_fun  => false
   }.

-spec is_dynamic(type()) -> boolean().
is_dynamic(#{?TYPE := ?M, meta := Meta}) when is_map(Meta) ->
  maps:get(dynamic, Meta, false);
is_dynamic(#{?TYPE := ?M}) ->
  false.

-spec is_macro(type()) -> boolean().
is_macro(#{?TYPE := ?M, meta := Meta}) when is_map(Meta) ->
  maps:get(macro, Meta, false);
is_macro(#{?TYPE := ?M}) ->
  false.

-spec is_public(type()) -> boolean().
is_public(#{?TYPE := ?M, meta := Meta}) when is_map(Meta) ->
  not maps:get(private, Meta, false);
is_public(#{?TYPE := ?M}) ->
  true.

-spec is_bound(type()) -> boolean().
is_bound(#{?TYPE := ?M} = Var) ->
  case deref(Var) of
    ?UNBOUND -> false;
    _ -> true
  end.

-spec has_root(type()) -> boolean().
has_root(#{?TYPE := ?M, meta := Meta}) when is_map(Meta) ->
  maps:get(has_root, Meta, false);
has_root(#{?TYPE := ?M}) ->
  false.

-spec get(type()) -> boolean().
get(Var) -> deref(Var).

-spec module(type()) -> atom().
module(#{?TYPE := ?M, ns_atom := NsAtom}) ->
  NsAtom.

-spec function(type()) -> atom().
function(#{?TYPE := ?M, name_atom := NameAtom}) ->
  NameAtom.

-spec val_function(type()) -> atom().
val_function(#{?TYPE := ?M, val_atom := ValAtom}) ->
  ValAtom.

-spec mark_fake_fun(type()) -> type().
mark_fake_fun(#{?TYPE := ?M} = Var) ->
  Var#{fake_fun => true}.

-spec push_bindings('clojerl.IMap':type()) -> ok.
push_bindings(BindingsMap) ->
  Bindings      = get_bindings(),
  NewBindings   = clj_scope:new(Bindings),
  AddBindingFun = fun(K, Acc) ->
                      clj_scope:put( clj_rt:str(K)
                                   , {ok, clj_rt:get(BindingsMap, K)}
                                   , Acc
                                   )
                  end,
  NewBindings1  = lists:foldl( AddBindingFun
                             , NewBindings
                             , clj_rt:to_list(clj_rt:keys(BindingsMap))
                             ),
  erlang:put(dynamic_bindings, NewBindings1),
  ok.

-spec pop_bindings() -> ok.
pop_bindings() ->
  Bindings = get_bindings(),
  Parent   = clj_scope:parent(Bindings),
  erlang:put(dynamic_bindings, Parent),
  ok.

-spec get_bindings() -> clj_scope:scope().
get_bindings() ->
  case erlang:get(dynamic_bindings) of
    undefined -> ?NIL;
    Bindings  -> Bindings
  end.

-spec get_bindings_map() -> map().
get_bindings_map() ->
  case get_bindings() of
    ?NIL      -> #{};
    Bindings  ->
      UnwrapFun = fun(_, {ok, X}) -> X end,
      clj_scope:to_map(UnwrapFun, Bindings)
  end.

-spec reset_bindings(clj_scope:scope()) -> ok.
reset_bindings(Bindings) ->
  erlang:put(dynamic_bindings, Bindings).

-spec dynamic_binding('clojerl.Var':type()) -> any().
dynamic_binding(Var) ->
  Key = clj_rt:str(Var),
  clj_scope:get(Key, get_bindings()).

-spec dynamic_binding('clojerl.Var':type(), any()) -> any().
dynamic_binding(Var, Value) ->
  case get_bindings() of
    ?NIL ->
      push_bindings(#{}),
      dynamic_binding(Var, Value);
    Bindings  ->
      Key = clj_rt:str(Var),
      NewBindings = case clj_scope:update(Key, {ok, Value}, Bindings) of
                      not_found ->
                        clj_scope:put(Key, {ok, Value}, Bindings);
                      NewBindingsTemp ->
                        NewBindingsTemp
                    end,
      erlang:put(dynamic_bindings, NewBindings),
      Value
  end.

-spec find('clojerl.Symbol':type()) -> type() | ?NIL.
find(QualifiedSymbol) ->
  NsName = clj_rt:namespace(QualifiedSymbol),
  ?ERROR_WHEN( NsName =:= ?NIL
             , <<"Symbol must be namespace-qualified">>
             ),

  Ns = 'clojerl.Namespace':find(clj_rt:symbol(NsName)),
  ?ERROR_WHEN( Ns =:= ?NIL
             , [<<"No such namespace: ">>, NsName]
             ),

  'clojerl.Namespace':find_var(Ns, QualifiedSymbol).

%%------------------------------------------------------------------------------
%% Protocols
%%------------------------------------------------------------------------------

name(#{?TYPE := ?M, name := Name}) ->
  Name.

namespace(#{?TYPE := ?M, ns := Ns}) ->
  Ns.

str(#{?TYPE := ?M, ns := Ns, name := Name}) ->
  <<"#'", Ns/binary, "/", Name/binary>>.

deref(#{ ?TYPE    := ?M
       , ns       := Ns
       , name     := Name
       , ns_atom  := Module
       , val_atom := FunctionVal
       } = Var) ->
  %% HACK
  Fun = resolve_fun(Var, Module, FunctionVal, 0),

  try
    %% Make the call in case the module is not loaded and handle the case
    %% when it doesn't even exist gracefully.
    Fun()
  catch
    ?WITH_STACKTRACE(Type, undef, Stacktrace)
      case erlang:function_exported(Module, FunctionVal, 0) of
        false -> throw(<<"Could not dereference ",
                         Ns/binary, "/", Name/binary, ". "
                         "There is no Erlang function "
                         "to back it up.">>);
        true  -> erlang:raise(Type, undef, Stacktrace)
      end
  end.

equiv( #{?TYPE := ?M, ns := Ns, name := Name}
     , #{?TYPE := ?M, ns := Ns, name := Name}
     ) ->
  true;
equiv(_, _) ->
  false.

hash(#{?TYPE := ?M, ns := Ns, name := Name}) ->
  erlang:phash2({Ns, Name}).

meta(#{?TYPE := ?M, meta := Meta}) -> Meta.

with_meta(#{?TYPE := ?M} = Var, Metadata) ->
  Var#{meta => Metadata}.

apply(#{?TYPE := ?M, ns_atom := Module, name_atom := Function} = Var, Args0) ->
  {Arity, Args1} = process_args(Var, Args0, fun clj_rt:seq/1),
  Fun            = resolve_fun(Var, Module, Function, Arity),

  erlang:apply(Fun, Args1).

-spec process_args(type(), [any()], function()) -> {arity(), [any()]}.
process_args( #{?TYPE := ?M, meta := #{'variadic?' := true} = Meta}
            , Args
            , RestFun
            ) ->
  #{ max_fixed_arity := MaxFixedArity
   , variadic_arity  := VariadicArity
   } = Meta,
  {Length, Args1, Rest} = bounded_length(Args, VariadicArity),
  if
    MaxFixedArity =:= ?NIL
    orelse Rest =/= ?NIL
    orelse (MaxFixedArity < Length andalso Length >= VariadicArity)->
      {Length + 1, Args1 ++ [RestFun(Rest)]};
    true ->
      {Length, Args1}
  end;
process_args(#{?TYPE := ?M}, Args, _RestFun) ->
  Args1 = clj_rt:to_list(Args),
  {length(Args1), Args1}.

bounded_length(Args, Max) when is_list(Args) ->
  Length = length(Args),
  case Length =< Max of
    true  -> {Length, Args, ?NIL};
    false ->
      {Args1, Rest} = lists:split(Max, Args),
      {Max, Args1, Rest}
  end;
bounded_length(?NIL, Max) ->
  bounded_length(?NIL, 0, Max, []);
bounded_length(Args, Max) ->
  TypeModule = clj_rt:type_module(Args),
  bounded_length(TypeModule:seq(Args), 0, Max, []).

bounded_length(?NIL, N, _Max, Acc) ->
  {N, lists:reverse(Acc), ?NIL};
bounded_length(Rest, N, _Max = N, Acc) ->
  {N, lists:reverse(Acc), Rest};
bounded_length(Rest, N, Max, Acc) ->
  TypeModule = clj_rt:type_module(Rest),
  First = TypeModule:first(Rest),
  Rest1 = TypeModule:next(Rest),
  bounded_length(Rest1, N + 1, Max, [First | Acc]).

%%------------------------------------------------------------------------------
%% Helper functions
%%------------------------------------------------------------------------------

-spec resolve_fun(type(), module(), atom(), arity()) -> fun().
resolve_fun(#{fake_fun := false}, Module, Function, Arity) ->
  fun Module:Function/Arity;
resolve_fun(_, Module, Function, Arity) ->
  clj_module:fake_fun(Module, Function, Arity).
