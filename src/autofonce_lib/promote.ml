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

open Ez_file.V1
open EzFile.OP

module Patch_lines = Autofonce_patch.Patch_lines
module Parser = Autofonce_core.Parser
module Misc = Autofonce_misc.Misc
open Types

let print_actions ~not_exit ~keep_old b actions =
  let rec string_of_check check =
    let b = Buffer.create 1000 in
    Buffer.add_string b "AT_CHECK(";
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
          if not_exit || keep_old then check.check_retcode
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
          if keep_old then check.check_stdout else
            match check.check_stdout with
            | Ignore -> Ignore
            | Content old_content ->
                let check_stdout =
                  Printf.sprintf "%s.out.subst" check_prefix in
                if Sys.file_exists check_stdout then
                  let s = EzFile.read_file check_stdout in
                  Content s
                else
                  Content old_content
        in
        match stdout with
        | Content content ->
            let s = Parser.m4_escape content in
            if Buffer.length b + String.length s > 80 then
              Printf.bprintf b ",\n%s" s
            else
              Printf.bprintf b ", %s" s
        | Ignore ->
            match check.check_stderr with
            | Ignore -> ()
            | _ ->
                Printf.bprintf b ", [ignore]"
      end;

      begin
        let stderr =
          if keep_old then check.check_stderr else
            match check.check_stderr with
            | Ignore -> Ignore
            | Content old_content ->
                let check_stderr =
                  Printf.sprintf "%s.err.subst" check_prefix in
                if Sys.file_exists check_stderr then
                  let s = EzFile.read_file check_stderr in
                  Content s
                else
                  Content old_content
        in
        match stderr with
        | Ignore -> ()
        | Content content ->
            let s = Parser.m4_escape content in
            if Buffer.length b + String.length s > 80 then
              Printf.bprintf b ",\n%s" s
            else
              Printf.bprintf b ", %s" s
      end;

    end else begin (* no promotion of this test, only internal ones *)

      begin
        match check.check_retcode with
        | None ->
            Printf.bprintf b ", [ignore]"
        | Some retcode ->
            Printf.bprintf b ", [%d]" retcode;
      end;

      let print_check_std check_std =
        match check_std with
        | Ignore ->
            Printf.bprintf b ", [ignore]"
        | Content content ->
            let s = Parser.m4_escape content in
            if Buffer.length b + String.length s > 80 then
              Printf.bprintf b ",\n%s" s
            else
              Printf.bprintf b ", %s" s
      in

      print_check_std check.check_stdout ;
      print_check_std check.check_stderr ;

      begin
        match check.check_run_if_fail with
        | [] ->
            Printf.bprintf b ", []"
        | actions ->
            Printf.bprintf b ", [\n";
            print_actions b actions;
            Printf.bprintf b "]";
      end;

      begin
        match check.check_run_if_pass with
        | [] -> ()
        | actions ->
            Printf.bprintf b ", [\n";
            print_actions b actions;
            Printf.bprintf b "]"
      end
    end ;
    Buffer.add_string b ")" ;
    Buffer.contents b

  and print_action b action =
    match action with
    | AT_CLEANUP _ -> Printf.bprintf b "\nAT_CLEANUP";
    | AT_DATA { file ; content } ->
        Printf.bprintf b "AT_DATA(%s, %s)\n"
          ( Parser.m4_escape file )
          ( Parser.m4_escape content )
    | AF_ENV string ->
        Printf.bprintf b "AT_ENV(%s)\n"
          ( Parser.m4_escape string )
    | AT_CAPTURE_FILE string ->
        Printf.bprintf b "AT_CAPTURE_FILE(%s)\n"
          ( Parser.m4_escape string )
    | AT_XFAIL ->
        Printf.bprintf b "AT_XFAIL_IF([true])\n"
    | AT_SKIP ->
        Buffer.add_string b "AT_SKIP_IF([true])\n"
    | AT_FAIL _ ->
        Buffer.add_string b "AT_FAIL_IF([true])\n"
    | AT_XFAIL_IF { command ; _ } ->
        Printf.bprintf b "AT_XFAIL_IF([%s])\n" ( Parser.m4_escape command )
    | AT_SKIP_IF { command ; _ } ->
        Printf.bprintf b "AT_SKIP_IF([%s])\n" ( Parser.m4_escape command )
    | AT_FAIL_IF { command ; _ } ->
        Printf.bprintf b "AT_FAIL_IF([%s])\n" ( Parser.m4_escape command )
    | AF_COPY { files ; copy ; promote ; _ } ->
        if promote then
          Printf.bprintf b "AF_%s([%s])\n"
            (if copy then "COPY" else "LINK")
            ( String.concat "], ["
                ( List.map Parser.m4_escape files ))
    | AT_CHECK check ->
        Printf.bprintf b "\n%s\n" ( string_of_check check )
    | AF_COMMENT comment ->
        Printf.bprintf b "#%s\n\n" comment

  and print_actions b actions =
    List.iter ( print_action b ) actions

  in
  print_actions b actions
