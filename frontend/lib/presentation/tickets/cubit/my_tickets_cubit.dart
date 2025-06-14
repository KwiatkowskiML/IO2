import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/presentation/tickets/cubit/my_tickets_state.dart';

class MyTicketsCubit extends Cubit<MyTicketsState> {
  final TicketRepository _ticketRepository;

  MyTicketsCubit(this._ticketRepository) : super(MyTicketsInitial());

  Future<void> loadTickets() async {
    try {
      emit(MyTicketsLoading());
      final tickets = await _ticketRepository.getMyTickets();
      emit(MyTicketsLoaded(allTickets: tickets));
    } on ApiException catch (e) {
      emit(MyTicketsError(e.message));
    } catch (e) {
      emit(MyTicketsError('An unexpected error occurred: $e'));
    }
  }

  void setFilter(TicketFilter filter) {
    if (state is MyTicketsLoaded) {
      final loadedState = state as MyTicketsLoaded;
      emit(MyTicketsLoaded(
        allTickets: loadedState.allTickets,
        activeFilter: filter,
      ));
    }
  }

  Future<void> listForResale(int ticketId, double price) async {
    if (state is! MyTicketsLoaded) return;
    final loadedState = state as MyTicketsLoaded;

    emit(TicketUpdateInProgress(
        allTickets: loadedState.allTickets,
        activeFilter: loadedState.activeFilter,
        processingTicketId: ticketId));

    try {
      await _ticketRepository.listTicketForResale(ticketId, price);
      await loadTickets();
    } on ApiException catch (e) {
      emit(MyTicketsError(e.message));
    } catch (e) {
      emit(const MyTicketsError('Failed to list ticket for resale.'));
    }
  }

  Future<void> cancelResale(int ticketId) async {
    if (state is! MyTicketsLoaded) return;
    final loadedState = state as MyTicketsLoaded;

    emit(TicketUpdateInProgress(
        allTickets: loadedState.allTickets,
        activeFilter: loadedState.activeFilter,
        processingTicketId: ticketId));

    try {
      await _ticketRepository.cancelResaleListing(ticketId);
      await loadTickets();
    } on ApiException catch (e) {
      emit(MyTicketsError(e.message));
    } catch (e) {
      emit(const MyTicketsError('Failed to cancel resale.'));
    }
  }
}
