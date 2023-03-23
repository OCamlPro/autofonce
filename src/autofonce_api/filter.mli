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
val filter_keywords: string list -> suite -> suite

(** [filter_retcode retcode testsuite] returns a testsuite with only the checks that have a return
    code that is equal to [retcode]. *)
val filter_retcode: int option -> suite -> suite
