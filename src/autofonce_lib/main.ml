(**************************************************************************)
(*                                                                        *)
(*  Copyright (c) 2023 OCamlPro SAS                                       *)
(*                                                                        *)
(*  All rights reserved.                                                  *)
(*  This file is distributed under the terms of the GNU General Public    *)
(*  License version 3.0, as described in the LICENSE.md file in the root  *)
(*  directory of this source tree.                                        *)
(*                                                                        *)
(*                                                                        *)
(**************************************************************************)

open Ezcmd.V2

module Misc = Autofonce_misc.Misc

let set_verbosity n =
  Globals.verbose := n;
  Call.debug := !Globals.verbose > 1

let get_verbosity () = !Globals.verbose

module PROGRAM = struct
  let command = "autofonce"
  let about = "autofonce COMMAND COMMAND-OPTIONS"
  let set_verbosity = set_verbosity
  let get_verbosity = get_verbosity
  let backtrace_var = Some "AUTOFONCE_BACKTRACE"
  let usage = "Modern runner for GNU Autoconf testsuites"
  let version = Version.version
  exception Error = Misc.Error
end
module MAIN = EZCMD.MAKE( PROGRAM )
include PROGRAM

let commands = [
  Command_init.cmd ;
  Command_list.cmd ;
  Command_run.cmd ;
  Command_new.cmd ;
  Command_promote.cmd ;
]

let main () =

  begin
    try ignore ( Sys.getcwd () )
    with _ ->
      Printf.eprintf "Current directory does not exist anymore. Move back up.\n%!";
      exit 2
  end ;
  Printexc.record_backtrace true;

  let common_args = [
  ] in

  MAIN.main
    ~on_error: (fun () -> () )
    ~on_exit: (fun () -> () )
    ~print_config: (fun () -> () )
    (* ~argv *)
    commands
    ~common_args;
