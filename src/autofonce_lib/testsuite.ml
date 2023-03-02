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

open EzCompat (* for IntMap *)
open Ezcmd.V2
open EZCMD.TYPES
open Ez_file.V1
open EzFile.OP

module MISC = Autofonce_misc.Misc
module PARSER = Autofonce_core.Parser
module CONFIG = Autofonce_config.Project_config
open Types
open Globals (* toplevel references *)

let testsuite = ref ( None : string option )
let output = ref None (* full path to results.log *)

let testsuite_file = ref None
let testsuite_env = ref None (* path to env file *)
let testsuite_path = ref []

(* returns run_dir and project_config *)
let find_project_config () =
  match MISC.find_file Autofonce_config.Globals.project_config_build with
  | exception Not_found ->
      begin
        match MISC.find_file Autofonce_config.Globals.project_config_source with
        | exception Not_found ->
            Printf.eprintf "Error: files %S or %S not found in top dirs\n%!"
              Autofonce_config.Globals.project_config_build
              Autofonce_config.Globals.project_config_source ;
            Printf.eprintf
              "  Use `autofonce init` to create a file %S.\n"
              Autofonce_config.Globals.project_config_build ;
            exit 2
        | file ->
            Autofonce_config.Project_config.from_file file
      end
  | file ->
      Autofonce_config.Project_config.from_file file

let read p tc =
  let testsuite_file = p.project_source_dir // tc.config_file in
  if not (Sys.file_exists testsuite_file) then
    MISC.error "Could not find testsuite file %S in project" testsuite_file ;
  let path = List.map (fun path ->
      p.project_source_dir // path
    ) tc.config_path in
  Printf.eprintf "Loading tests from file %S\n%!" testsuite_file ;
  let suite = PARSER.read ~path testsuite_file in
  p, tc, suite

let find () =

  begin
    if not ( Sys.file_exists ( Sys.getcwd () )) then
      MISC.error "Current directory does not exist anymore. Move back up.\n%!";
  end ;

  begin
    try
      let file = MISC.find_file "autofonce.env" in
      MISC.error
        "File %S found. This file is deprecated, remove it and run `autofonce init`" file
    with Not_found -> ()
  end;

  let p = find_project_config () in

  let p =
    match !testsuite_file with
    | None -> p
    | Some config_file ->
        let env = match !testsuite_env with
          | None ->
              {
                env_name = "";
                env_kind = Env_content ;
                env_content = "";
              }
          | Some testsuite_env ->
              {
                env_name = "";
                env_kind = Env_file testsuite_env ;
                env_content = EzFile.read_file testsuite_env ;
              }
        in
        let config_name = match !testsuite with
          | None -> ""
          | Some config_name -> config_name
        in
        let t = {
          config_name ;
          config_file ;
          config_path = List.rev !testsuite_path ;
          config_env = env ;
        } in
        { p with
          project_envs = StringMap.add "" env p.project_envs ;
          project_testsuites = t :: p.project_testsuites ;
        }
  in
  Printf.eprintf "Project description loaded from %s\n%!" p.project_file;
  let tc =
    match !testsuite with
    | None ->
        begin
          match p.project_testsuites with
          | [] -> MISC.error
                    "Project does not define any testsuite in %s !\n"
                    p.project_file
          | tc :: _ -> tc
        end
    | Some testsuite ->
        let rec iter testsuites =
          match testsuites with
          | [] ->
              MISC.error "Testsuite %S not found among testsuites in %s\n%!"
                testsuite p.project_file
          | tc :: testsuites ->
              if tc.config_name = testsuite then tc else
                iter testsuites
        in
        iter p.project_testsuites
  in
  read p tc

let log_header state fmt =
  let b = state.state_buffer in
  Printf.kprintf (fun s ->
      Buffer.add_string b "\n#######################################\n";
      Printf.bprintf b    "#\n#          %50s\n#\n" s;
      Buffer.add_string b "#######################################\n\n";
    ) fmt

let log_failed_tests _state _msg _tests = () (* TODO *)

let log_captured_files state =  (* TODO *)
  let b = state.state_buffer in
  let p = state.state_project in
  let dir = p.project_source_dir in
  List.iter (fun file ->
      log_header state "Project captured %S" file ;
      let filename = dir // file in
      match EzFile.read_file filename with
      | exception exn ->
          Printf.bprintf b "Exception while reading %S:\n  %s\n"
            filename ( Printexc.to_string exn )
      | file ->
          Printf.bprintf b "\n```\n%s```\n" file
    ) p.project_captured_files

let exec p tc suite =
  MISC.set_signal_handle Sys.sigint (fun _ -> exit 2);
  MISC.set_signal_handle Sys.sigterm (fun _ -> exit 2);

  let state = Runner_common.create_state p tc suite in
  (* we are now in state_run_dir, i.e. before _autofonce/ *)

  let tests_dir = Autofonce_config.Globals.tests_dir in
  if !clean_tests_dir && Sys.file_exists tests_dir then
    MISC.remove_rec tests_dir ;

  if not ( Sys.file_exists tests_dir ) then begin
    Runner_common.output state "Creating testing directory %s\n%!"
      (Sys.getcwd () // tests_dir);
    Unix.mkdir tests_dir 0o755;
  end else begin
    Runner_common.output state "Using testing directory %s\n%!"
      (Sys.getcwd () // tests_dir);
  end;

  if !max_jobs = 1 then
    Runner_seq.exec_testsuite state
  else
    Runner_par.exec_testsuite state;

  Terminal.move_bol ();
  Printf.printf "Results:\n%!"; Terminal.erase Eol;
  Terminal.printf [] "* %d checks performed\n%!" state.state_nchecks ;
  let style =
    if state.state_tests_failed <> [] then [ Terminal.red ]
    else [ Terminal.green ]
  in
  Terminal.printf style
    "* %d / %d tests executed successfully\n%!"
    state.state_ntests_ok state.state_ntests_ran ;
  begin match state.state_tests_failed with
    | [] -> ()
    | list ->
        let nb = List.length list in
        Terminal.printf [ Terminal.red ] "* %d tests failed:" nb;
        Runner_common.print_ntests 10 (List.rev list);
        Printf.printf "\n%!";
  end;
  begin match state.state_tests_skipped with
    | [] -> ()
    | list ->
        let nb = List.length list in
        Terminal.printf [ Terminal.magenta ]
          "* %d tests were skipped\n%!" nb;
  end;
  begin match state.state_tests_failexpected with
    | [] -> ()
    | list ->
        let nb = List.length list in
        Terminal.printf [ Terminal.magenta ]
          "* %d tests were expected to fail:%!" nb;
        Runner_common.print_ntests 5 (List.rev list);
        Printf.printf "\n%!";
  end;
  if !print_all then begin
    let buffer = Buffer.contents state.state_buffer in
    Terminal.printf [ Terminal.magenta ] "%s\n%!" buffer;
  end ;
  begin
    log_failed_tests state "Failures" state.state_tests_failed ;
    log_failed_tests state "Expected Failures" state.state_tests_failed ;
    log_captured_files state ;

    let buffer_file = match !output with
      | None -> Sys.getcwd () // tests_dir // "results.log"
      | Some output -> output
    in
    let buffer = Buffer.contents state.state_buffer in
    EzFile.write_file buffer_file buffer;
    Printf.eprintf "File %S created with failure results\n%!" buffer_file;
  end ;
  List.length state.state_tests_failed

let print_test _c t =
  Printf.printf "%04d %-50s %s\n%!" t.test_id t.test_name
    ( PARSER.name_of_loc t.test_loc );
  ()

let print c =
  let current_banner = ref "" in
  Filter.select_tests
    (fun t ->
       if t.test_banner <> !current_banner then begin
         Printf.eprintf "\n%s\n\n%!" t.test_banner;
         current_banner := t.test_banner
       end;
       print_test c t;
    ) c

let args = [

  [ "t" ; "testsuite" ], Arg.String (fun s -> testsuite := Some s),
  EZCMD.info
    ~env:(EZCMD.env "AUTOFONCE_TESTSUITE")
    ~docv:"TESTSUITE" "Name of the testsuite to run (as specified in 'autofonce.toml')";

  [ "o" ; "output" ], Arg.String (fun s -> output := Some s),
  EZCMD.info
    ~env:(EZCMD.env "AUTOFONCE_OUTPUT")
    ~docv:"TESTSUITE" "Path of the output file (default: _autofonce/results.log)";

  [ "T" ; "at" ], Arg.String (fun s -> testsuite_file := Some s),
  EZCMD.info
    ~docv:"TESTSUITE.at" "Path of the file containing the testsuite" ;

  [ "E" ; "env" ], Arg.String (fun s -> testsuite_env := Some s),
  EZCMD.info
    ~docv:"TESTSUITE.sh" "Env file for all tests" ;

  [ "I" ], Arg.String (fun s -> testsuite_path := s :: !testsuite_path),
  EZCMD.info
    ~docv:"DIR" "Add DIR to search path for tests" ;


]
