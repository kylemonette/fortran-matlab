subroutine multiply_matrices(A, B, C_out)
    use, intrinsic :: iso_c_binding
    implicit none

    ! Declare 2x2 double precision matrices matching MATLAB's double type
    real(c_double), intent(in)  :: A(2,2), B(2,2)
    real(c_double), intent(out) :: C_out(2,2)

    ! Perform native Fortran matrix multiplication
    C_out = matmul(A, B)
end subroutine multiply_matrices