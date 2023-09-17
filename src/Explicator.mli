(** @inline *)
include module type of ExplicatorData

(** {1 Explication} *)

include module type of ExplicatorSigs

(** Making an explicator. *)
module Make : Reader -> functor (Style : Style) -> S with module Style := Style