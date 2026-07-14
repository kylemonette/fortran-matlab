subroutine compute_product(val1, val2, result)
    ! Bind to C to ensure easy cross-language integration
    use, intrinsic :: iso_c_binding
    implicit none

    real(c_double), intent(in) :: val1, val2
    real(c_double), intent(out) :: result

    result = val1 * val2
end subroutine compute_product