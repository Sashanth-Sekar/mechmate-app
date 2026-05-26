import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Vehicle } from './vehicle.entity';
import { Booking } from './booking.entity';
import { Workshop } from './workshop.entity';

export enum UserRole {
  OWNER = 'owner',
  MECHANIC = 'mechanic',
  WORKSHOP = 'workshop',
  ADMIN = 'admin',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  firebaseUid: string;

  @Column({ length: 100 })
  name: string;

  @Column({ unique: true, length: 255 })
  email: string;

  @Column({ length: 20, nullable: true })
  phone: string;

  @Column({
    type: 'simple-enum',
    enum: UserRole,
    default: UserRole.OWNER,
  })
  role: UserRole;

  @Column({ nullable: true })
  avatarUrl: string;

  @Column({ default: true })
  isActive: boolean;

  // Geo-location
  @Column({ length: 100, nullable: true })
  country: string;

  @Column({ length: 10, nullable: true })
  countryCode: string;

  @Column({ length: 100, nullable: true })
  state: string;

  @Column({ length: 10, nullable: true })
  stateCode: string;

  @Column({ length: 100, nullable: true })
  city: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @OneToMany(() => Vehicle, (vehicle) => vehicle.owner)
  vehicles: Vehicle[];

  @OneToMany(() => Booking, (booking) => booking.owner)
  bookings: Booking[];

  @OneToMany(() => Workshop, (workshop) => workshop.owner)
  workshops: Workshop[];
}
