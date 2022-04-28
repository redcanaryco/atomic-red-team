#include <security/pam_modules.h>

PAM_EXTERN int pam_sm_setcred( pam_handle_t *pamh, int flags, int argc, const char **argv ) {
    return PAM_SUCCESS;
}

PAM_EXTERN int pam_sm_authenticate(pam_handle_t *pamh, int flags,int argc, const char **argv) {
    return PAM_SUCCESS;
}
