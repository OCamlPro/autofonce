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

open EzCompat
(* open Ez_win32.V1 *)
open Ezcmd.V2
(* open EZCMD.TYPES *)
open Ez_file.V1
(* open Ez_call.V1  *)
open Ez_subst.V2

module Misc = Autofonce_misc.Misc
module Parser = Autofonce_core.Parser

let regen_file filename =
  let lines = EzFile.read_lines filename in
  let dirname = Filename.dirname filename in
  let b = Buffer.create 10000 in

  let must_cleanup = ref false in
  let topmap = ref StringMap.empty in
  let map = ref StringMap.empty in

  let cleanup () =
    if !must_cleanup then begin
      Printf.bprintf b "\nAT_CLEANUP\n\n";
      must_cleanup := false ;
      map := !topmap ;
    end else begin
      topmap := !map
    end;
    Printf.bprintf b
      "\n\n\n#############################################################\n\n";
  in

  let unescape s =
    let len = String.length s in
    if len >=2 && s.[0] = '"' && s.[len-1] = '"' then
      String.sub s 1 (len-2)
    else s
  in

  let get lnum s = try
      StringMap.find s !map
    with Not_found ->
      Misc.error "%s:%d: variable %S not found" filename lnum s
  in

  let subst lnum s =
    let brace lnum s =
      let rec iter var cmds =
        match cmds with
        | [] -> var
        | cmd :: cmds ->
            let var = match cmd with
              | "basename" -> Filename.chop_extension var
              | "get" -> get lnum var
              | "read" -> EzFile.read_file (Filename.concat dirname var)
              | "read?" ->
                  let file = Filename.concat dirname var in
                  if Sys. file_exists file then EzFile.read_file file
                  else ""
              | _ -> Misc.error "Subst: function %%{%s} not defined" cmd
            in
            iter var cmds
      in
      let s = String.lowercase_ascii s in
      let list = List.rev @@ EzString.split s ':' in
      match list with
      | [] -> Misc.error "Subst: empty string"
      | var :: "string" :: cmds -> iter var cmds
      | var :: cmds ->
          let var =
            let maybe_not_found, var =
              let len = String.length var in
              if len > 0 && var.[0] = '?' then
                true, String.sub var 1 (len-1)
              else
                false, var
            in
            try StringMap.find var !map with
            | _ ->
                if maybe_not_found then "" else
                  Misc.error "Subst: variable %%{%s} not defined" var
          in
          iter var cmds
    in
    EZ_SUBST.string ~ctxt: lnum ~sep:'%' ~brace s
  in
  let set name value =
    map := StringMap.add name value !map
  in
  let rec reset value =
    if StringMap.mem value !map then begin
      map := StringMap.remove value !map;
      reset value
    end else
      match StringMap.find value !topmap with
      | exception Not_found -> ()
      | v ->
          map := StringMap.add value v !map
  in

  set "num" "";
  set "exit" "0";
  set "stdout" "";
  set "stderr" "";

  Array.iteri (fun lnum line ->

      let len = String.length line in
      if len > 0 && line.[0] <> '#' then
        let cmd, value = EzString.cut_at line ':' in
        let value = String.trim value in
        match cmd with
        | "test" ->
            cleanup ();
            Printf.bprintf b "\n\nAT_SETUP(%s)\n" (Parser.m4_escape value);
            must_cleanup := true
        | "keywords" ->
            Printf.bprintf b "AT_KEYWORDS(%s)\n\n"
              (Parser.m4_escape (subst lnum value))
        | "reset" -> reset value
        | "set" ->
            let name, value = EzString.cut_at value ':' in
            let name = String.trim name in
            let value = unescape @@ String.trim value in
            set name value
        | "comment" -> Printf.bprintf b "# %s\n" value
        | "skip" -> Printf.bprintf b "%s"
                      ( String.make (try int_of_string value with _ -> 1) '\n' )
        | "data" ->
            let file1, file2 =
              let file1, file2 = EzString.cut_at value ':' in
              let file2 = if file2 = "" then file1 else file2 in
              file1, file2
            in
            let basename = Filename.basename file1 in
            let contents = EzFile.read_file (Filename.concat dirname file2) in
            Printf.bprintf b "AT_DATA(%s,%s)\n"
              (Parser.m4_escape basename)
              (Parser.m4_escape contents);
        | "target" ->
            let contents = EzFile.read_file (Filename.concat dirname value) in
            Printf.bprintf b "AT_DATA(%s,%s)\n"
              (Parser.m4_escape (Filename.basename value))
              (Parser.m4_escape contents);
            set "target" (Filename.basename value)
        | "check" ->
            set "check" value ;
            let command = subst lnum @@ get lnum value in
            let exit = subst lnum @@ get lnum "exit" in
            let stdout = subst lnum @@ get lnum "stdout" in
            let stderr = subst lnum @@ get lnum "stderr" in
            Printf.bprintf b "\nAT_CHECK(%s, %s, %s, %s)\n"
              (Parser.m4_escape command)
              (Parser.m4_escape exit)
              (Parser.m4_escape stdout)
              (Parser.m4_escape stderr)
        | "save" ->

            cleanup ();
            let output = Filename.concat dirname value in
            let new_contents = Buffer.contents b in
            Buffer.clear b;
            let old_contents = try EzFile.read_file output with _ -> "" in
            if new_contents <> old_contents then begin
              EzFile.write_file output new_contents;
              Printf.eprintf "File %S regenerated\n%!" output
            end
        | _ -> Misc.error "Unknown command %S" cmd
    ) lines

let regen () =
  let rec iter dirname =
    let files = Sys.readdir dirname in
    Array.iter (fun basename ->
        let filename = Filename.concat dirname basename in
        if try Sys.is_directory filename with _ -> false then
          iter filename
        else
          let ext = Filename.extension basename in
          if ext = ".atscript" then
            regen_file filename
      ) files
  in
  iter "."

let cmd =
  let args = [] in
  EZCMD.sub "regen" regen
    ~args
    ~doc: "Generate a testsuite"
    ~man:[
      `S "DESCRIPTION";
      `Blocks [
        `P {|Generates a full testsuite in directory tests/ from a set of data files.|}
      ];
    ]
