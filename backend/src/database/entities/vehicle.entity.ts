import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';
import { User } from './user.entity';
import { Booking } from './booking.entity';

@Entity('vehicles')
export class Vehicle {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 20 })
  type: string; // 'Car' | 'Bike'

  @Column({ length: 50 })
  number: string;

  @Column({ length: 100 })
  make: string;

  @Column({ length: 100 })
  model: string;

  @Column({ type: 'int' })
  year: number;

  @Column({ length: 50, nullable: true })
  color: string;

  @Column({ nullable: true })
  fuelType: string;

  @Column({ nullable: true })
  registrationNumber: string;

  @Column({ type: 'int', nullable: true })
  odometerReading: number;

  @Column({ nullable: true })
  insuranceDetails: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations
  @ManyToOne(() => User, (user) => user.vehicles)
  @JoinColumn({ name: 'ownerId' })
  owner: User;

  @Column()
  ownerId: string;

  @OneToMany(() => Booking, (booking) => booking.vehicle)
  bookings: Booking[];
}
