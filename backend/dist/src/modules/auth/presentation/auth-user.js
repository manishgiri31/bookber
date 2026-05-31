export function getAuthUser(request) {
    const tokenUser = request.user;
    return {
        id: tokenUser.sub,
        fullName: "",
        email: "",
        phoneNumber: null,
        role: tokenUser.role,
        profileImage: null
    };
}
export function getAuthUserFromDb(tokenUser, user) {
    return {
        id: tokenUser.sub,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: tokenUser.role,
        profileImage: user.profileImage
    };
}
