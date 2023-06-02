module History

#=
# from vim source:
/*
 * Structure defining text properties.  These stick with the text.
 * When stored in memline they are after the text, ml_line_len is larger than
 * STRLEN(ml_line_ptr) + 1.
 */
typedef struct textprop_S
{
    colnr_T	tp_col;		// start column (one based, in bytes)
    colnr_T	tp_len;		// length in bytes, when tp_id is negative used
				// for left padding plus one
    int		tp_id;		// identifier
    int		tp_type;	// property type
    int		tp_flags;	// TP_FLAG_ values
} textprop_T;


/*
 * structures used for undo
 */

// One line saved for undo.  After the NUL terminated text there might be text
// properties, thus ul_len can be larger than STRLEN(ul_line) + 1.
typedef struct {
    char_u	*ul_line;	// text of the line
    long	ul_len;		// length of the line including NUL, plus text
				// properties
} undoline_T;
typedef struct u_entry u_entry_T;
typedef struct u_header u_header_T;
struct u_entry
{
    u_entry_T	*ue_next;	// pointer to next entry in list
    linenr_T	ue_top;		// number of line above undo block
    linenr_T	ue_bot;		// number of line below undo block
    linenr_T	ue_lcount;	// linecount when u_save called
    undoline_T	*ue_array;	// array of lines in undo block
    long	ue_size;	// number of lines in ue_array
#ifdef U_DEBUG
    int		ue_magic;	// magic number to check allocation
#endif
};

struct u_header
{
    // The following have a pointer and a number. The number is used when
    // reading the undo file in u_read_undo()
    union {
	u_header_T *ptr;	// pointer to next undo header in list
	long	   seq;
    } uh_next;
    union {
	u_header_T *ptr;	// pointer to previous header in list
	long	   seq;
    } uh_prev;
    union {
	u_header_T *ptr;	// pointer to next header for alt. redo
	long	   seq;
    } uh_alt_next;
    union {
	u_header_T *ptr;	// pointer to previous header for alt. redo
	long	   seq;
    } uh_alt_prev;
    long	uh_seq;		// sequence number, higher == newer undo
    int		uh_walk;	// used by undo_time()
    u_entry_T	*uh_entry;	// pointer to first entry
    u_entry_T	*uh_getbot_entry; // pointer to where ue_bot must be set
    pos_T	uh_cursor;	// cursor position before saving
    long	uh_cursor_vcol;
    int		uh_flags;	// see below
    pos_T	uh_namedm[NMARKS];	// marks before undo/after redo
    visualinfo_T uh_visual;	// Visual areas before undo/after redo
    time_T	uh_time;	// timestamp when the change was made
    long	uh_save_nr;	// set when the file was saved after the
				// changes in this block
#ifdef U_DEBUG
    int		uh_magic;	// magic number to check allocation
#endif
};
=#

struct LineDiff
    index :: Int64
    text :: String
end

+(x::LineDiff, y::LineDiff) = 

    function buffer(diff :: LineDiff)
end



function test_line_diff()
end


end
