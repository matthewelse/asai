module type S =
sig
  module Code : Code.S

  (** [messagef ~loc ~additional_marks ~code format ...] constructs a diagnostic along with the backtrace frames recorded via [tracef]. *)
  val messagef : ?loc:Span.t -> ?additional_marks:Span.t list -> ?severity:Severity.t -> code:Code.t -> ('a, Format.formatter, unit, Code.t Diagnostic.t) format4 -> 'a

  (** [kmessagef kont ~loc ~additional_marks ~code format ...] constructs a diagnostic and then apply [kont] to the resulting diagnostic. *)
  val kmessagef : (Code.t Diagnostic.t -> 'b) -> ?loc:Span.t -> ?additional_marks:Span.t list -> ?severity:Severity.t -> code:Code.t -> ('a, Format.formatter, unit, 'b) format4 -> 'a

  (** [tracef ~loc format ...] record a frame. *)
  val tracef : ?loc:Span.t -> ('a, Format.formatter, unit, (unit -> 'b) -> 'b) format4 -> 'a

  (** [append_marks msg marks] appends [marks] to the additional marks of [msg]. *)
  val append_marks : Code.t Diagnostic.t -> Span.t list -> Code.t Diagnostic.t

  (** Emit a diagnostic and continue the computation. *)
  val emit : Code.t Diagnostic.t -> unit

  (** [emitf ~loc ~additional_marks ~code format ...] constructs and emits a diagnostic. *)
  val emitf : ?loc:Span.t -> ?additional_marks:Span.t list -> ?severity:Severity.t -> code:Code.t -> ('a, Format.formatter, unit, unit) format4 -> 'a

  (** Emit a diagnostic and abort the computation. *)
  val fatal: Code.t Diagnostic.t -> 'a

  (** [fatalf ~loc ~additional_marks ~code format ...] constructs a diagnostic and abort the current computation. *)
  val fatalf : ?loc:Span.t -> ?additional_marks:Span.t list -> ?severity:Severity.t -> code:Code.t -> ('a, Format.formatter, unit, 'b) format4 -> 'a

  (** [run ~emit ~fatal f] runs the thunk [f], using [emit] to handle emitted diagnostics before continuing
      the computation, and [fatal] to handle diagnostics after aborting the computation. *)
  val run : emit:(Code.t Diagnostic.t -> unit) -> fatal:(Code.t Diagnostic.t -> 'a) -> (unit -> 'a) -> 'a

  (** [try_with ~emit ~fatal f] runs the thunk [f], using [emit] to intercept emitted diagnostics before continuing
      the computation, and [fatal] to intercept diagnostics after aborting the computation. The default interceptors
      reperform or reraise the intercepted diagnostics. *)
  val try_with : ?emit:(Code.t Diagnostic.t -> unit) -> ?fatal:(Code.t Diagnostic.t -> 'a) -> (unit -> 'a) -> 'a
end
