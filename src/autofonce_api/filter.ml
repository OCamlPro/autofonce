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

open Autofonce_lib.Types

(** [filter_keywords keywords testsuite] returns a testsuite in which all the tests have at least one
    of the keywords in the [keywords] list. *)
let filter_keywords keywords testsuite =
  {testsuite with
   suite_tests =
     List.filter
       (fun {test_keywords; _} ->
          List.exists
            (fun kw ->
               Option.is_some
               @@ List.find_opt ((=) kw) keywords)
            test_keywords)
       testsuite.suite_tests
  }

(** [filter_retcode retcode testsuite] returns a testsuite with only the checks that have a return
    code that is equal to [retcode]. *)
let filter_retcode retcode testsuite =
  {testsuite with
   suite_tests =
     List.map (fun ({test_actions; _} as test) ->
         {test with
          test_actions = List.filter (function
              | AT_CHECK {check_retcode; _} when check_retcode <> retcode -> false
              |_ -> true)
              test_actions
         })
       testsuite.suite_tests
  }
