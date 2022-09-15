module type S =
sig
  module Code : Code.S

  (** [messagef ~loc ~additional_marks code format ...] constructs a diagnostic along with the backtrace frames recorded via [tracef]. *)
  val messagef : ?loc:Span.t -> ?additional_marks:Span.t list -> ?severity:Severity.t -> Code.t -> ('a, Format.formatter, unit, Code.t Diagnostic.t) format4 -> 'a

  (** [kmessagef kont ~loc ~additional_marks code format ...] constructs a diagnostic and then apply [kont] to the resulting diagnostic. *)
  val kmessagef : (Code.t Diagnostic.t -> 'b) -> ?loc:Span.t -> ?additional_marks:Span.t list -> ?severity:Severity.t -> Code.t -> ('a, Format.formatter, unit, 'b) format4 -> 'a

  (** [tracef ~loc format ...] record a frame. *)
  val tracef : ?loc:Span.t -> ('a, Format.formatter, unit, (unit -> 'b) -> 'b) format4 -> 'a

  (** [ktracef kont ~loc format ... x] record a frame, running [kont x] to create a thunk that will be run with the new backtrace.
      The call [kont x] itself is run with the current backtrace, and the thunk returned by [kont x] is run with the new backtrace augmented with the frame. *)
  val ktracef : ('a -> unit -> 'b) -> ?loc:Span.t -> ('c, Format.formatter, unit, 'a -> 'b) format4 -> 'c

  (** [append_marks msg marks] appends [marks] to the additional marks of [msg]. *)
  val append_marks : Code.t Diagnostic.t -> Span.t list -> Code.t Diagnostic.t

  (** Emit a diagnostic and continue the computation. *)
  val emit : Code.t Diagnostic.t -> unit

  (** [emitf ~loc ~additional_marks code format ...] constructs and emits a diagnostic. *)
  val emitf : ?loc:Span.t -> ?additional_marks:Span.t list -> ?severity:Severity.t -> Code.t -> ('a, Format.formatter, unit, unit) format4 -> 'a

  (** Emit a diagnostic and abort the computation. *)
  val fatal: Code.t Diagnostic.t -> 'a

  (** [fatalf ~loc ~additional_marks code format ...] constructs a diagnostic and abort the current computation. *)
  val fatalf : ?loc:Span.t -> ?additional_marks:Span.t list -> ?severity:Severity.t -> Code.t -> ('a, Format.formatter, unit, 'b) format4 -> 'a

  (** [run ~emit ~fatal f] runs the thunk [f], using [emit] to handle emitted diagnostics before continuing
      the computation, and [fatal] to handle diagnostics after aborting the computation. *)
  val run : ?init_backtrace:Diagnostic.message Span.located Bwd.bwd
    -> emit:(Code.t Diagnostic.t -> unit) -> fatal:(Code.t Diagnostic.t -> 'a) -> (unit -> 'a) -> 'a

  (** [wrap w run f] runs the thunk [f] that possibly uses different error codes, using the runner [run] possibly from a different instance of this module. The diagnostics [d] generated by [f] are wrapped by the function [w]. The backtrace generated by [f] will include the backtrace that leads to [wrap]. The intended use case is to wrap diagnostics generated from a library to diagnostics in the main application.

      Here shows an example, where [Lib] is the library:
      {[
        module MainLogger = Logger.Make(Code)
        module LibLogger = Lib.Logger

        let _ = MainLogger.wrap (Diagnostic.map code_mapper) Lib.run Lib.some_feature
      ]}
  *)
  val wrap :
    ('code Diagnostic.t -> Code.t Diagnostic.t) ->
    (?init_backtrace:Diagnostic.message Span.located Bwd__BwdDef.bwd ->
     emit:('code Diagnostic.t -> unit) -> fatal:('code Diagnostic.t -> 'a) -> (unit -> 'a) -> 'a) ->
    (unit -> 'a) -> 'a

  (** [try_with ~emit ~fatal f] runs the thunk [f], using [emit] to intercept emitted diagnostics before continuing
      the computation, and [fatal] to intercept diagnostics after aborting the computation. The default interceptors
      reperform or reraise the intercepted diagnostics. *)
  val try_with : ?emit:(Code.t Diagnostic.t -> unit) -> ?fatal:(Code.t Diagnostic.t -> 'a) -> (unit -> 'a) -> 'a
end
