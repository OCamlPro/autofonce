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

open Types

exception FAILED of tester * location * string
exception SKIPPED_FAIL of checker * string
exception SKIP

let failed_check job s = raise (FAILED (job.checker_tester,
                                        job.checker_check.check_loc,
                                        s))

let failed_test ter s = raise (FAILED (ter,
                                       ter.tester_test.test_loc,
                                        s))

let rec exec_action_or_check ter action =
  match action with
  | AT_SKIP -> raise SKIP
  | AT_FAIL -> failed_test ter "AT_FAIL_IF"
  | AT_CHECK check -> exec_check ter check
  | AT_XFAIL_IF { step ; loc ; command } ->
      exec_check ter ( Runner_common.check_of_AT_XFAIL_IF ter step loc command )
  | AT_SKIP_IF { step ; loc ; command } ->
      exec_check ter ( Runner_common.check_of_AT_SKIP_IF ter step loc command )
  | AT_FAIL_IF { step ; loc ; command } ->
      exec_check ter ( Runner_common.check_of_AT_FAIL_IF ter step loc command )
  | AT_COPY { step ; loc ; command ; _ } ->
      exec_check ter (
        Runner_common.check_of_at_file ~copy:true ter step loc command )
  | AT_LINK { step ; loc ; command ; _ } ->
      exec_check ter (
        Runner_common.check_of_at_file ~copy:false ter step loc command )

  | AT_XFAIL
  | AT_DATA _
  | AT_CAPTURE_FILE _
  | AT_CLEANUP _
  | AT_ENV _
    ->
      Runner_common.exec_action_no_check ter action

and exec_check ter check =
  let cer = Runner_common.start_check ter check in
  let ret_pid, status = Call.wait_pids () in
  let retcode =
    assert (ret_pid = cer.checker_pid );
    let ret_code =
      match status with
      | WEXITED n -> n
      | WSIGNALED _ -> -1 (* TODO: what ? *)
      | WSTOPPED _ ->
          ( try Unix.kill Sys.sigkill cer.checker_pid with _ -> ());
          ( try Unix.kill Sys.sigcont cer.checker_pid with _ -> ());
          -1
    in
    ret_code
  in
  let failures = Runner_common.check_failures cer retcode in
  begin
    match failures with
    | [] -> (* SUCCESS *)
        List.iter (exec_action_or_check ter) check.check_run_if_pass
    | failures ->
        begin
          match check.check_run_if_fail with
          | [] ->
              let failures = String.concat " " failures in
              if retcode = 77 then
                raise (SKIPPED_FAIL (cer, failures))
              else
                failed_check cer failures
          | actions ->
              List.iter (exec_action_or_check ter) actions
        end
  end

let exec_test state t =
  let ter = Runner_common.start_test state t in
  state.state_status <- Printf.sprintf "running test %04d" t.test_id ;
  state.state_status_printed <- false;
  Runner_common.print_status state;
  begin try
      List.iter (exec_action_or_check ter) t.test_actions;
      Runner_common.test_is_ok ter
    with
    | FAILED (ter, loc ,s) ->
        Runner_common.test_is_failed loc ter s
    | SKIPPED_FAIL (job,s) ->
        Runner_common.test_is_skipped_fail job s
    | SKIP ->
        Runner_common.test_is_skip ter
  end;
  ()

let exec_testsuite state =
  let suite = state.state_suite in
  Filter.select_tests ~state (fun t ->
      if t.test_banner <> state.state_banner then begin
        Runner_common.output state "%s" t.test_banner;
        state.state_banner <- t.test_banner
      end;
      exec_test state t;
    ) suite
