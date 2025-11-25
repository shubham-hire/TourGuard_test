export declare enum UserRole {
    USER = "USER",
    ADMIN = "ADMIN"
}
export declare class User {
    id: string;
    email: string;
    password: string;
    name: string;
    role: UserRole;
    phone?: string;
    hashId?: string;
    profilePhotoUrl?: string;
    otpVerified: boolean;
    lastLogin?: Date;
    createdAt: Date;
    updatedAt: Date;
}
