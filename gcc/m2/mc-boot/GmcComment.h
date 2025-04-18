/* do not edit automatically generated by mc from mcComment.  */
/* mcComment.def provides a module to remember the comments.

Copyright (C) 2015-2025 Free Software Foundation, Inc.
Contributed by Gaius Mulley <gaius.mulley@southwales.ac.uk>.

This file is part of GNU Modula-2.

GNU Modula-2 is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

GNU Modula-2 is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Modula-2; see the file COPYING3.  If not see
<http://www.gnu.org/licenses/>.  */


#if !defined (_mcComment_H)
#   define _mcComment_H

#include "config.h"
#include "system.h"
#   ifdef __cplusplus
extern "C" {
#   endif
#include <stdbool.h>
#   if !defined (PROC_D)
#      define PROC_D
       typedef void (*PROC_t) (void);
       typedef struct { PROC_t proc; } PROC;
#   endif

#   include "GSYSTEM.h"
#   include "GDynamicStrings.h"
#   include "GnameKey.h"

#   if defined (_mcComment_C)
#      define EXTERN
#   else
#      define EXTERN extern
#   endif

#if !defined (mcComment_commentDesc_D)
#  define mcComment_commentDesc_D
   typedef void *mcComment_commentDesc;
#endif


/*
   initComment - the start of a new comment has been seen by the lexical analyser.
                 A new comment block is created and all addText contents are placed
                 in this block.  onlySpaces indicates whether we have only seen
                 spaces on this line.  The new comment descriptor is returned.
		 If onlySpaces is TRUE then an inbody comment is created.
		 If onlySpaces is FALSE then an after statement comment is created.
*/

EXTERN mcComment_commentDesc mcComment_initComment (bool onlySpaces);

/*
   addText - cs is a C string (null terminated) which contains comment text.
*/

EXTERN void mcComment_addText (mcComment_commentDesc cd, void * cs);

/*
   getContent - returns the content of comment, cd.
*/

EXTERN DynamicStrings_String mcComment_getContent (mcComment_commentDesc cd);

/*
   getCommentCharStar - returns the contents of the comment, cd.
*/

EXTERN void * mcComment_getCommentCharStar (mcComment_commentDesc cd);

/*
   setProcedureComment - changes the type of comment, cd, to a
                         procedure heading comment,
                         providing it has the procname as the first word.
*/

EXTERN void mcComment_setProcedureComment (mcComment_commentDesc cd, nameKey_Name procname);

/*
   getProcedureComment - returns the procedure comment if available.
*/

EXTERN DynamicStrings_String mcComment_getProcedureComment (mcComment_commentDesc cd);

/*
   getAfterStatementComment - returns the after comment if available.
*/

EXTERN DynamicStrings_String mcComment_getAfterStatementComment (mcComment_commentDesc cd);

/*
   getInbodyStatementComment - returns the statement comment if available.
*/

EXTERN DynamicStrings_String mcComment_getInbodyStatementComment (mcComment_commentDesc cd);

/*
   isProcedureComment - returns TRUE if, cd, is a procedure comment.
*/

EXTERN bool mcComment_isProcedureComment (mcComment_commentDesc cd);

/*
   isBodyComment - returns TRUE if, cd, is a body comment.
*/

EXTERN bool mcComment_isBodyComment (mcComment_commentDesc cd);

/*
   isAfterComment - returns TRUE if, cd, is an after comment.
*/

EXTERN bool mcComment_isAfterComment (mcComment_commentDesc cd);
#   ifdef __cplusplus
}
#   endif

#   undef EXTERN
#endif
