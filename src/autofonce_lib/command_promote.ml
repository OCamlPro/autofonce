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
open Ez_file.V1
open EzFile.OP

module Patch_lines = Autofonce_patch.Patch_lines
module Parser = Autofonce_core.Parser
module Misc = Autofonce_misc.Misc
open Types
open Globals

(* TODO: check why the ignore pattern does not work *)
let diff = Patch_lines.Diff { exclude = [ "^# promoted on .*" ]}
let todo = ref diff
let comment = ref true
let not_exit = ref false

let promote p tc suite =
  Filter.only_failed := true ;
  Patch_lines.reset ();
  let state = Runner_common.create_state p tc suite in
  Unix.chdir state.state_run_dir ;
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

    if !comment then
      Printf.bprintf b "%s\n" comment_line;

    begin
      match t.test_keywords with
      | [] -> ()
      | list ->
          Printf.bprintf b "AT_KEYWORDS(%s)\n"
            (Parser.m4_escape (String.concat " " list))
    end;

    let rec print_check check =
      let check_dir = Runner_common.check_dir check in
      let check_prefix = check_dir // Runner_common.check_prefix check in
      Printf.bprintf b "%s" ( Parser.m4_escape check.check_command );
      (* AT_CHECK can be used as a 'if', in which case either
         run-if-pass or run-if-fail is not empty. Otherwise,
         the check must pass after promotion.
      *)
      if
        check.check_run_if_pass = [] && check.check_run_if_fail = []
      then begin

        begin
          let retcode =
            if !not_exit then check.check_retcode
            else
              match check.check_retcode with
              | None -> None
              | Some old_retcode ->
                  let check_exit = Printf.sprintf "%s.exit" check_prefix in
                  if Sys.file_exists check_exit then
                    let s = EzFile.read_file check_exit in
                    let retcode = int_of_string s in
                    Some retcode
                  else
                    Some old_retcode
          in
          match retcode with
          | None ->
              Printf.bprintf b ", [ignore]"
          | Some retcode ->
              if retcode <> 0 then
                Printf.bprintf b ", [%d]" retcode
              else
                match check.check_stdout, check.check_stderr with
                | Ignore, Ignore -> ()
                | _ ->
                    Printf.bprintf b ", [%d]" retcode;
        end;

        begin
          let stdout =
            match check.check_stdout with
            | Ignore -> Ignore
            | Content old_content ->
                let check_stdout = Printf.sprintf "%s.out" check_prefix in
                if Sys.file_exists check_stdout then
                  let s = EzFile.read_file check_stdout in
                  Content s
                else
                  Content old_content
          in
          match stdout with
          | Content old_content ->
              Printf.bprintf b ", %s" (Parser.m4_escape old_content)
          | Ignore ->
              match check.check_stderr with
              | Ignore -> ()
              | _ ->
                  Printf.bprintf b ", [ignore]"
        end;

        begin
          let stderr =
            match check.check_stderr with
            | Ignore -> Ignore
            | Content old_content ->
                let check_stderr = Printf.sprintf "%s.err" check_prefix in
                if Sys.file_exists check_stderr then
                  let s = EzFile.read_file check_stderr in
                  Content s
                else
                  Content old_content
          in
          match stderr with
          | Ignore -> ()
          | Content content ->
              Printf.bprintf b ", %s" (Parser.m4_escape content)
        end;

      end else begin (* no promotion of this test, only internal ones *)

        begin
          match check.check_retcode with
          | None ->
              Printf.bprintf b ", [ignore]"
          | Some retcode ->
              Printf.bprintf b ", [%d]" retcode;
        end;

        begin
          match check.check_stdout with
          | Ignore ->
              Printf.bprintf b ", [ignore]"
          | Content content ->
              Printf.bprintf b ", %s" (Parser.m4_escape content)
        end;

        begin
          match check.check_stderr with
          | Ignore ->
              Printf.bprintf b ", [ignore]"
          | Content content ->
              Printf.bprintf b ", %s" (Parser.m4_escape content)
        end;

        begin
          match check.check_run_if_fail with
          | [] ->
              Printf.bprintf b ", []"
          | actions ->
              Printf.bprintf b ", [\n";
              print_actions actions;
              Printf.bprintf b "]";
        end;

        begin
          match check.check_run_if_pass with
          | [] -> ()
          | actions ->
              Printf.bprintf b ", [\n";
              print_actions actions;
              Printf.bprintf b "]"
        end
      end

    and print_action action =
      match action with
      | AT_CLEANUP _ -> Printf.bprintf b "\nAT_CLEANUP";
      | AT_DATA { file ; content } ->
          Printf.bprintf b "AT_DATA(%s,%s)\n"
            ( Parser.m4_escape file )
            ( Parser.m4_escape content )
      | AT_ENV string ->
          Printf.bprintf b "AT_ENV(%s)\n"
            ( Parser.m4_escape string )
      | AT_CAPTURE_FILE string ->
          Printf.bprintf b "AT_CAPTURE_FILE(%s)\n"
            ( Parser.m4_escape string )
      | AT_XFAIL ->
          Printf.bprintf b "AT_XFAIL_IF([true])\n"
      | AT_SKIP ->
          Buffer.add_string b "AT_SKIP_IF([true])\n"
      | AT_FAIL ->
          Buffer.add_string b "AT_FAIL_IF([true])\n"
      | AT_XFAIL_IF { command ; _ } ->
          Printf.bprintf b "AT_XFAIL_IF([%s])\n" ( Parser.m4_escape command )
      | AT_SKIP_IF { command ; _ } ->
          Printf.bprintf b "AT_SKIP_IF([%s])\n" ( Parser.m4_escape command )
      | AT_FAIL_IF { command ; _ } ->
          Printf.bprintf b "AT_FAIL_IF([%s])\n" ( Parser.m4_escape command )
      | AT_COPY { files ; _ } ->
          Printf.bprintf b "AT_COPY([%s])\n"
            ( String.concat "],["
                ( List.map Parser.m4_escape files ))
      | AT_LINK { files ; _ } ->
          Printf.bprintf b "AT_LINK([%s])\n"
            ( String.concat "],["
                ( List.map Parser.m4_escape files ))
      | AT_CHECK  check ->
          Buffer.add_string b "AT_CHECK(";
          print_check check ;
          Buffer.add_string b ")\n"

    and print_actions actions =
      List.iter print_action actions

    in
    print_actions t.test_actions;

    let content = Buffer.contents b in
    Patch_lines.replace_block ~file ~line_first ~line_last content
  in
  Filter.select_tests ~state promote_test suite;

  Patch_lines.commit_to_disk ~action:!todo ();
  ()

let args auto_promote_arg = [

  [ "no-comment" ], Arg.Clear comment,
  EZCMD.info ~env:(EZCMD.env "AUTOFONCE_PROMOTE_NO_COMMENT")
    "Do not add a comment with the promotion date";

  [ "not-exit" ], Arg.Set not_exit,
  EZCMD.info "Do not promote exit code" ;

  [ auto_promote_arg ], Arg.Int (fun n ->
      auto_promote := n ;
      todo := Apply ;
    ),
  EZCMD.info
    "Promote and run until all tests have been promoted"

]

let rec action p tc suite =
  promote p tc suite ;
  if !auto_promote > 0 then begin
    Filter.only_failed := true ;
    clean_tests_dir := false ;
    let n = Testsuite.exec p tc suite in
    decr auto_promote;
    if n>0 then
      let (p, tc, suite) = Testsuite.read p tc in
      action p tc suite
  end

let cmd =
  let args =
    Testsuite.args @
    Filter.args @
    args "auto-run" @
    [

      [ "apply" ], Arg.Unit (fun () -> todo := Apply),
      EZCMD.info "Apply promotion (default is to diff)" ;

      [ "diff" ], Arg.Unit (fun () -> todo := diff),
      EZCMD.info "Diff promotion (default)" ;

      [ "fake" ], Arg.String (fun ext -> todo := Fake ext),
      EZCMD.info ~docv:".EXT"
        "Apply promotion to create new files with extension $(docv)" ;

    ]
  in
  EZCMD.sub
    "promote"
    (fun () ->
       let p, tc, suite = Testsuite.find () in
       action p tc suite
    )
    ~args
    ~doc: "Promote tests results as expected results"
    ~man:[
      `S "DESCRIPTION";
      `Blocks [
        `P {|After an unsucessful testsuite run, use this command to promote the results of tests to expected status.|} ;
      ];
    ]
