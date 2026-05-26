import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

export enum PaymentStatus {
  PENDING = 'pending',
  SUCCESS = 'success',
  FAILED = 'failed',
  REFUNDED = 'refunded',
}

export enum PaymentMethod {
  RAZORPAY = 'razorpay',
  STRIPE = 'stripe',
  UPI = 'upi',
  WALLET = 'wallet',
  CASH = 'cash',
}

@Entity('payments')
export class Payment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  bookingId: string;

  @Column({ length: 100 })
  ownerId: string;

  @Column({ length: 100, nullable: true })
  workshopId: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number;

  @Column({
    type: 'simple-enum',
    enum: PaymentMethod,
    default: PaymentMethod.RAZORPAY,
  })
  paymentMethod: PaymentMethod;

  @Column({
    type: 'simple-enum',
    enum: PaymentStatus,
    default: PaymentStatus.PENDING,
  })
  status: PaymentStatus;

  @Column({ length: 100, nullable: true })
  transactionId: string;

  @Column({ length: 255, nullable: true })
  gatewayResponse: string;

  @CreateDateColumn()
  createdAt: Date;
}
