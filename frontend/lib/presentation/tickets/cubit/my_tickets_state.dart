import 'package:equatable/equatable.dart';
import 'package:resellio/core/models/ticket_model.dart';

enum TicketFilter { all, upcoming, resale }

abstract class MyTicketsState extends Equatable {
  const MyTicketsState();
  @override
  List<Object?> get props => [];
}

class MyTicketsInitial extends MyTicketsState {}

class MyTicketsLoading extends MyTicketsState {}

class MyTicketsLoaded extends MyTicketsState {
  final List<TicketDetailsModel> allTickets;
  final TicketFilter activeFilter;

  const MyTicketsLoaded({
    required this.allTickets,
    this.activeFilter = TicketFilter.all,
  });

  List<TicketDetailsModel> get filteredTickets {
    switch (activeFilter) {
      case TicketFilter.upcoming:
        return allTickets
            .where((t) =>
                t.eventStartDate != null &&
                t.eventStartDate!.isAfter(DateTime.now()) &&
                t.resellPrice == null)
            .toList();
      case TicketFilter.resale:
        return allTickets.where((t) => t.resellPrice != null).toList();
      case TicketFilter.all:
      default:
        return allTickets;
    }
  }

  @override
  List<Object?> get props => [allTickets, activeFilter];
}

class MyTicketsError extends MyTicketsState {
  final String message;
  const MyTicketsError(this.message);

  @override
  List<Object> get props => [message];
}

class TicketUpdateInProgress extends MyTicketsLoaded {
  final int processingTicketId;

  const TicketUpdateInProgress({
    required super.allTickets,
    required super.activeFilter,
    required this.processingTicketId,
  });

  @override
  List<Object?> get props => [super.props, processingTicketId];
}
