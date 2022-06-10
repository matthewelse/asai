open Bwd

open Loc

module Hashtbl = Hashtbl.Make (String)

module Make (ErrorCode : ErrorCode.S) =
struct

  type env = {
    buffers : string Hashtbl.t;
    span   : Span.t option
  }

  module Diagnostic = Diagnostic.Make (ErrorCode)
  module Reader = Algaeff.Reader.Make (struct type nonrec env = env end)

  type _ Effect.t +=
    | Survivable : Diagnostic.t -> unit Effect.t
    | Fatal : Diagnostic.t -> 'a Effect.t

  exception Panic

  let build ~code message =
    Diagnostic.build ~code message

  let cause message diag =
    let env = Reader.read () in
    match env.span with
    | Some location ->
      Diagnostic.with_cause ~location ~message diag
    | None ->
      diag

  let emit diag =
    Effect.perform (Survivable diag)

  let fatal diag =
    Effect.perform (Fatal diag)

  let load_file ~filepath contents =
    let env = Reader.read () in
    Hashtbl.add env.buffers filepath contents

  let locate span k =
    Reader.scope (fun env -> { env with span = Some span }) k

  let position pos k =
    Reader.scope (fun env -> { env with span = Some (Span.spanning pos pos) }) k

  (* [TODO: Reed M, 07/06/2022] Right now this returns an exit code, is that corrrect?? *)
  let run k =
    let open Effect.Deep in
    (* [TODO: Reed M, 07/06/2022] This isn't thread safe, I should probably add a mutex for the hashtable. *)
    let buffers = Hashtbl.create 32 in
    let diagnostics = ref Emp in
    Reader.run ~env:{ buffers; span = None } @@ fun () ->
    begin
      try
        try_with k ()
          { effc = fun (type a) (eff : a Effect.t) ->
                match eff with
                | Survivable diag -> Option.some @@ fun (k : (a, _) continuation) ->
                  diagnostics := Snoc(!diagnostics, diag);
                  continue k ()
                | Fatal diag -> Option.some @@ fun (k : (a, _) continuation) ->
                  diagnostics := Snoc(!diagnostics, diag);
                  discontinue k Panic
                | _ -> None
          }
      with Panic ->
        ()

    end;
    Bwd.to_list @@ !diagnostics

  (* [TODO: Reed M, 07/06/2022] Right now this returns an exit code, is that corrrect?? *)
  let run_display ~display k =
    let open Effect.Deep in
    (* [TODO: Reed M, 07/06/2022] This isn't thread safe, I should probably add a mutex for the hashtable. *)
    let buffers = Hashtbl.create 32 in
    Reader.run ~env:{ buffers; span = None } @@ fun () ->
    try
      try_with k ()
        { effc = fun (type a) (eff : a Effect.t) ->
              match eff with
              | Survivable diag -> Option.some @@ fun (k : (a, _) continuation) ->
                display ~buffers diag;
                continue k ()
              | Fatal diag -> Option.some @@ fun (k : (a, _) continuation) ->
                display ~buffers diag;
                discontinue k Panic
              | _ -> None
        };
      0
    with Panic ->
      1
end