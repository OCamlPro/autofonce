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

type location = Autofonce_m4.M4Types.location

type check_output =
  | Ignore
  | Content of string

type check = { (* variable name is `check` *)
  check_loc : location ;
  check_step : string ;
  check_command : string ;
  check_retcode : int option ;
  check_stdout : check_output ;
  check_stderr : check_output ;
  check_run_if_fail : action list ;
  check_run_if_pass : action list ;
  check_kind : string ;

  check_test : test ;
}

(* Actions currently unsupported:
 — Macro: AT_FAIL_IF (shell-condition)
*)

and action =
  | AT_DATA of { file:string ; content: string }
  | AT_CAPTURE_FILE of string
  | AT_XFAIL_IF of string
  | AT_SKIP
  | AT_CHECK of check
  | AT_CLEANUP of { loc : location }

and test = { (* variable name is `t` *)
  test_suite : suite ;
  test_loc : location ;
  test_name : string ;
  test_id : int ;
  test_banner : string ;
  mutable test_keywords : string list ;
  mutable test_actions : action list ;
}

and suite = { (* variable name is `c` *)
  suite_file : string ; (* name of testsuite.at *)
  suite_dir : string ; (* full dir of "testsuite.at" *)
  mutable suite_ntests : int ;
  suite_test_by_id : ( int, test ) Hashtbl.t ;
  mutable suite_tests : test list ;
  mutable suite_tested_programs : string list ;
  mutable suite_copyright : string ;
  mutable suite_name : string ;
  mutable suite_banners : string list ;
}

(* use M4Parser.name_of_loc for a shortened version *)
let string_of_location = Autofonce_m4.M4Printer.string_of_location

let rec string_of_action = function
  | AT_DATA { file ; content } ->
      Printf.sprintf "AT_DATA ( file=%S, content=%S )" file content
  | AT_CAPTURE_FILE string ->
      Printf.sprintf "AT_CAPTURE_FILE %s" string
  | AT_XFAIL_IF string ->
      Printf.sprintf "AT_XFAIL_IF %s" string
  | AT_SKIP ->
      "AT_SKIP"
  | AT_CHECK  check ->
      Printf.sprintf "AT_CHECK %s" ( string_of_check check )
  | AT_CLEANUP { loc } ->
      Printf.sprintf "AT_CLEANUP %s" ( string_of_location loc )

and string_of_check_output = function
    | Ignore -> "IGNORE"
    | Content s -> Printf.sprintf "EXPECT [%s]" s

and string_of_runif = function
  | [] -> ""
  | _ -> "[ACTIONS]"

and string_of_check c =
  let b = Buffer.create 1000 in
  Printf.bprintf b "{\n";
  Printf.bprintf b "  check_loc = %s;\n" (string_of_location c.check_loc);
  Printf.bprintf b "  step = %S;\n" c.check_step;
  Printf.bprintf b "  command = %S;\n" c.check_command;
  Printf.bprintf b "  retcode = %s;\n" (match c.check_retcode with
      | None -> "" | Some n -> string_of_int n);
  Printf.bprintf b "  stdout = %s;\n" (string_of_check_output c.check_stdout);
  Printf.bprintf b "  stderr = %s;\n" (string_of_check_output c.check_stderr);
  Printf.bprintf b "  run_if_fail = %s;\n"
    (string_of_runif c.check_run_if_fail);
  Printf.bprintf b "  run_if_pass = %s;\n"
    (string_of_runif c.check_run_if_pass);
  Printf.bprintf b "  }";
  Buffer.contents b