open Lsp.Types
module RPC := Jsonrpc

module Make (ErrorCode: Asai.ErrorCode.S) : sig
  module Doctor : module type of Asai.Effects.Make(ErrorCode)

  type lsp_error =
    | DecodeError of string
    | HandshakeError of string
    | ShutdownError of string
    | UnknownRequest of string
    | UnknownNotification of string

  exception LspError of lsp_error

  val recv : unit -> RPC.packet option
  val send : RPC.packet -> unit

  val should_shutdown : unit -> bool
  val initiate_shutdown : unit -> unit

  val set_root : string option -> unit
  val load_file : DocumentUri.t -> unit

  module Request : sig
    type packed = Lsp.Client_request.packed
    type 'resp t = 'resp Lsp.Client_request.t
    type msg = RPC.Id.t option RPC.Message.t

    val handle : RPC.Id.t -> msg -> RPC.Response.t
    val recv : unit -> (RPC.Id.t * packed) option
    val respond : RPC.Id.t -> 'resp t -> 'resp -> unit
  end

  module Notification : sig
    type msg = RPC.Id.t option RPC.Message.t
    type t = Lsp.Client_notification.t

    val handle : msg -> unit
    val recv : unit -> t option
  end

  val run : Eio.Stdenv.t
    -> init:(string option -> unit)
    -> load_file:(string -> unit)
    -> (unit -> 'a)
    -> 'a
end
