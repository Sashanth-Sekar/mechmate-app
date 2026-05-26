import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';
import { Vehicle } from './vehicle.entity';
import { Workshop } from './workshop.entity';

export enum BookingStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  ACTIVE = 'active',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
}

export enum BookingType {
  GENERAL = 'general',
  EMERGENCY = 'emergency',
  DOORSTEP = 'doorstep',
  PICKUP_DROP = 'pickup_drop',
  INSTANT = 'instant',
}

@Entity('bookings')
export class Booking {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'simple-enum',
    enum: BookingType,
    default: BookingType.GENERAL,
  })
  bookingType: BookingType;

  @Column({ length: 100 })
  service: string;

  @Column({
    type: 'simple-enum',
    enum: BookingStatus,
    default: BookingStatus.PENDING,
  })
  status: BookingStatus;

  @Column({ nullable: true })
  scheduledAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ type: 'text', nullable: true })
  notes: string;

  // Location for doorstep/pickup
  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  pickupLatitude: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  pickupLongitude: number;

  @Column({ length: 255, nullable: true })
  pickupAddress: string;

  // Payment
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  estimatedAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  finalAmount: number;

  @Column({ default: false })
  isPaid: boolean;

  @Column({ length: 50, nullable: true })
  paymentMethod: string;

  @Column({ length: 100, nullable: true })
  transactionId: string;

  // Mechanic assignment
  @Column({ length: 100, nullable: true })
  assignedMechanicName: string;

  @Column({ nullable: true })
  assignedMechanicId: string;

  // Relations
  @ManyToOne(() => User, (user) => user.bookings)
  @JoinColumn({ name: 'ownerId' })
  owner: User;

  @Column()
  ownerId: string;

  @ManyToOne(() => Vehicle, (vehicle) => vehicle.bookings)
  @JoinColumn({ name: 'vehicleId' })
  vehicle: Vehicle;

  @Column({ nullable: true })
  vehicleId: string;

  @ManyToOne(() => Workshop, (workshop) => workshop.bookings)
  @JoinColumn({ name: 'workshopId' })
  workshop: Workshop;

  @Column({ nullable: true })
  workshopId: string;
}
