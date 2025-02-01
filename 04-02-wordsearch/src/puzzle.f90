! Assumes FORTRAN 2023 standard
program puzzle
    use, intrinsic :: iso_fortran_env, only : error_unit

    ! Puzzle state
    character(len=4), parameter :: goal = "XMAS"
    character,allocatable :: board(:,:)
    integer :: goal_at, matches = 0

    ! File handling state
    character(len=:), allocatable :: path
    character :: char_in
    integer :: path_length, file_error

    ! Parser state
    integer, parameter :: ascii = selected_char_kind("ascii ") ! FORTRAN "newline" function too vague for my comfort
    character(len=1), parameter :: cr = char(13, ascii), lf = char(10, ascii)
    logical :: file_done = .false., line_done = .false.
    integer :: line_length = 0, current_line_length = 0, rows = 0, row_at = 1, col_at = 1, longer_axis

    if (1 /= command_argument_count()) then
        write(error_unit,*) "Expected 1 argument (filename)" ! write to stderr
        error stop
    end if

    ! Although F2023 (see https://wg5-fortran.org/N2201-N2250/N2212.pdf section 2.2)
    ! supports a deferred-length string being length-initialized by get_command_argument,
    ! GNU FORTRAN as of 14.2.0 appears to not do this and the path out is an empty string.
    ! Therefore, call twice, once to get the path length, and then after allocating call again
    ! to get the path. If called with expected (conformant?) behavior this is harmless.
    call get_command_argument(1, path, path_length)
    allocate(Character (path_length) :: path)
    call get_command_argument(1, path)

    ! Because automatic deferred length initialization is not working as expected,
    ! Don't try to read in the lines entire and instead read in character by character.
    ! We do this in two passes: Once to determine the grid size, and once to actually read.
    open(10,file=path,access='stream',form='unformatted',action='read',iostat=file_error)
    if (0 /= file_error) then
        write(error_unit,*) "File error", file_error ! write to stderr
        if (file_error == 2) write(error_unit,*) "(No such file)"
        error stop
    end if

    ! Pass to populate line_length, rows
    do
        read(10, iostat=file_error) char_in
        if (file_error > 0) then
            write(error_unit,*) "File read error", file_error ! write to stderr
            error stop
        end if
        file_done = file_error == -1
        line_done = file_done .or. char_in == cr .or. char_in == lf
!        print *, '[', char_in, ']', line_done, file_done

        ! End of line logic here
        if (line_done) then
            if (current_line_length /= 0) then !! Assume a zero length line is due to surplus newlines
                if (line_length == 0) then
                    line_length = current_line_length
                else
                    if (current_line_length < line_length) then
                        write(error_unit,*) "Line", file_error, rows+1, "too short:", line_length, current_line_length ! write to stderr
                        error stop
                    end if
                end if
                current_line_length = 0
                rows = rows + 1
            end if
        end if

        if (file_done) exit

        ! New character logic here
        if (.not. line_done) then
            current_line_length = current_line_length + 1
            if (line_length /= 0 .and. current_line_length > line_length) then
                write(error_unit,*) "Line", rows+1, "too long:", line_length, current_line_length ! write to stderr
                error stop
            end if
        end if
    end do

    ! Act

    if (0 == line_length) then
        write(error_unit,*) "File empty?" ! write to stderr
        error stop
    end if

    print *, "MAT", rows, line_length
    allocate(board (line_length, rows)) ! FORTRAN is column-major but this is not as I expect
    longer_axis = max(rows, line_length)

    ! Reset file
    ! AS FAR AS I KNOW THIS SHOULD WORK, BUT IT DOES NOT
    ! read(10, "()", advance='no', pos=1)

    ! Load in matrix
    ! Some repetition :(
    do
        if (row_at == 1 .and. col_at == 1) then
            read(10, iostat=file_error, pos=1) char_in
        else
            read(10, iostat=file_error) char_in
        end if

        if (file_error > 0) then
            write(error_unit,*) "File read error", file_error ! write to stderr
            error stop
        end if
        file_done = file_error == -1
        line_done = file_done .or. char_in == cr .or. char_in == lf
!        print *, '[', char_in, ']', line_done, file_done

        ! End of line logic here
        if (line_done) then
            if (col_at /= 1) then !! Assume a zero length line is due to surplus newlines
                col_at = 1
                row_at = row_at + 1
            end if
        end if

        if (file_done) exit

        ! New character logic here
        if (.not. line_done) then
            board(col_at, row_at) = char_in
            col_at = col_at + 1
        end if
    end do

    ! Okay ugh actually do the thing
    ! Note reuse: row_at, col_at

    ! "Euclidian"

    do row_at = 2,rows-1
        do col_at = 2, line_length-1
            if ( board(col_at, row_at) == 'A' .and. &
                 ((check(board, [col_at, row_at], [1,1])) .or. &
                  (check(board, [col_at, row_at], [-1,-1]))) .and. &
                 ((check(board, [col_at, row_at], [1,-1])) .or. &
                  (check(board, [col_at, row_at], [-1,1]))) &
            ) matches = matches + 1
        end do
   end do

    print *, size(board,1), size(board,2)

    print *,"FINAL", matches

contains

function check(board, at, offset) result (match)
    implicit none
    character,allocatable,intent(in) :: board(:,:)
    integer,dimension(2), intent(in) :: at,offset
    logical :: match

    integer,dimension(2) :: temp

    match = .true.

!    print *, "   is", at, offset

    temp = at + offset
!    print *, "Check1", temp, board(temp(1), temp(2))
    match = match .and. board(temp(1), temp(2)) == 'M'

    temp = at - offset
!    print *, "Check2", temp, board(temp(1), temp(2))
    match = match .and. board(temp(1), temp(2)) == 'S'
   
!    print *, "Result", match
!    print *, "" 
end function check

end program puzzle
