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
open EZCMD.TYPES

module Patch_lines = Autofonce_patch.Patch_lines
module Parser = Autofonce_core.Parser
module Misc = Autofonce_misc.Misc
open Types
open Filter

(* TODO: check why the ignore pattern does not work *)
let diff args = Patch_lines.Diff { exclude = [ "^# promoted on .*" ]; args }
let todo = ref (diff None)
let not_exit = ref false

let promote ~filter_args ~exec_args p tc suite =
  filter_args.arg_only_failed <- true ;
  Patch_lines.reset ();
  let state = Runner_common.create_state ~exec_args p tc suite in
  Unix.chdir state.state_run_dir ;
  (*
  let comment_line =
    let t = Unix.gettimeofday () in
    let tm = Unix.localtime t in
    Printf.sprintf "# promoted on %04d-%02d-%02dT%02d:%02d"
      ( 1900 + tm.tm_year )
      ( 1 + tm.tm_mon )
      tm.tm_mday
      tm.tm_hour
      tm.tm_min
  in
*)
  let promote_test t =
    let file = t.test_loc.file in
    Printf.eprintf "Promoting test %d %s\n%!"
      t.test_id ( Parser.name_of_loc t.test_loc );
    let line_first = t.test_loc.line in
    let line_last =
      match List.rev t.test_actions with
      | AT_CLEANUP { loc } :: _ -> loc.line
      | _ -> Misc.error
               "Last test in %s does not end with AT_CLEANUP ?" file
    in

    let b = Buffer.create 10000 in

    Printf.bprintf b "AT_SETUP(%s)\n" (Parser.m4_escape t.test_name);

    begin
      match t.test_keywords with
      | [] -> ()
      | list ->
          Printf.bprintf b "AT_KEYWORDS(%s)\n\n"
            (Parser.m4_escape (String.concat " " list))
    end;
    Promote.print_actions
      ~not_exit:!not_exit
      ~keep_old:false
      t b t.test_actions;

    let content = Buffer.contents b in
    Patch_lines.replace_block ~file ~line_first ~line_last content
  in
  Filter.select_tests ~args:filter_args ~state promote_test suite;

  Patch_lines.commit_to_disk ~action:!todo ();
  ()

let args auto_promote_arg ~exec_args = [

  [ "not-exit" ], Arg.Set not_exit,
  EZCMD.info "Do not promote exit code" ;

  [ "diff-args" ], Arg.String (fun s -> todo := diff (Some s)),
  EZCMD.info ~docv:"ARGS" "Pass these args to the diff command" ;

  [ auto_promote_arg ], Arg.Int (fun n ->
      exec_args.arg_auto_promote <- n ;
      todo := Apply ;
    ),
  EZCMD.info
    "Promote and run until all tests have been promoted"

]

let rec action ~filter_args ~exec_args p tc suite =
  promote ~filter_args ~exec_args p tc suite ;
  if exec_args.arg_auto_promote > 0 then begin
    filter_args.arg_only_failed <- true ;
    filter_args.arg_filter <- true ;
    let n = Testsuite.exec ~filter_args ~exec_args p tc suite in
    exec_args.arg_auto_promote <- exec_args.arg_auto_promote - 1;
    if n>0 then
      let (p, tc, suite) = Testsuite.read p tc in
      action ~filter_args ~exec_args p tc suite
  end

let cmd =
  let testsuite_args, get_testsuite_args = Testsuite.args () in
  let filter_args, get_filter_args = Filter.args () in
  let runner_args, exec_args = Runner_common.args () in
  let args =
    runner_args @
    testsuite_args @
    filter_args @
    args ~exec_args "auto-run" @
    [

      [ "apply" ], Arg.Unit (fun () -> todo := Apply),
      EZCMD.info "Apply promotion (default is to diff)" ;

      [ "diff" ], Arg.Unit (fun () -> todo := diff None),
      EZCMD.info "Diff promotion (default)" ;

      [ "fake" ], Arg.String (fun ext -> todo := Fake ext),
      EZCMD.info ~docv:".EXT"
        "Apply promotion to create new files with extension $(docv)" ;

    ]
  in
  EZCMD.sub
    "promote"
    (fun () ->
       let filter_args = get_filter_args () in
       let p, tc, suite = Testsuite.find ( get_testsuite_args () ) in
       action ~filter_args ~exec_args p tc suite
    )
    ~args
    ~doc: "Promote tests results as expected results"
    ~man:[
      `S "DESCRIPTION";
      `Blocks [
        `P {|After an unsucessful testsuite run, use this command to promote the results of tests to expected status.|} ;
      ];
    ]
