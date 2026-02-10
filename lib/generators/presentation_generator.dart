import 'base_generator.dart';

/// Generator for presentation layer (BLoC, pages, widgets)
class PresentationGenerator extends BaseGenerator {
  const PresentationGenerator(super.config);

  @override
  Future<void> generate() async {
    await generateBloc();
    await generateListPage();
    await generateDetailPage();
    await generateFormPage();
  }

  /// Generate BLoC (events, states, bloc)
  Future<void> generateBloc() async {
    await _generateEvents();
    await _generateStates();
    await _generateBlocClass();
  }

  Future<void> _generateEvents() async {
    await writeToFile(
      'lib/features/$featureName/presentation/bloc/${entitySingular}_event.dart',
      _eventTemplate,
    );
  }

  Future<void> _generateStates() async {
    await writeToFile(
      'lib/features/$featureName/presentation/bloc/${entitySingular}_state.dart',
      _stateTemplate,
    );
  }

  Future<void> _generateBlocClass() async {
    await writeToFile(
      'lib/features/$featureName/presentation/bloc/${entitySingular}_bloc.dart',
      _blocTemplate,
    );
  }

  Future<void> generateListPage() async {
    await writeToFile(
      'lib/features/$featureName/presentation/pages/${entitySingular}_list_page.dart',
      _listPageTemplate,
    );
  }

  Future<void> generateDetailPage() async {
    await writeToFile(
      'lib/features/$featureName/presentation/pages/${entitySingular}_detail_page.dart',
      _detailPageTemplate,
    );
  }

  Future<void> generateFormPage() async {
    // Generate entity constructor parameters with comments
    final userFieldsComments = config.userColumns.map((col) {
      final required = !col.isNullable ? 'required ' : '';
      final comment = '// ${required}${col.name}: ${col.dartType},  ← TODO: Add your value here';
      return '      $comment';
    }).join('\n');

    final formTemplate = _formPageTemplate.replaceAll(
      '// TODO_USER_FIELDS',
      userFieldsComments,
    );

    await writeToFile(
      'lib/features/$featureName/presentation/pages/${entitySingular}_form_page.dart',
      formTemplate,
    );
  }

  // Templates
  String get _eventTemplate => '''
import 'package:equatable/equatable.dart';
import 'package:$packageName/features/$featureName/domain/entities/$entitySingular.dart';

abstract class ${entityPascal}Event extends Equatable {
  const ${entityPascal}Event();

  @override
  List<Object?> get props => [];
}

class LoadAll$featurePascal extends ${entityPascal}Event {
  const LoadAll$featurePascal();
}

class Load${featurePascal}By${parentPascal}Id extends ${entityPascal}Event {
  final int ${parentCamel}Id;

  const Load${featurePascal}By${parentPascal}Id(this.${parentCamel}Id);

  @override
  List<Object?> get props => [${parentCamel}Id];
}

class Load${entityPascal}ById extends ${entityPascal}Event {
  final int id;

  const Load${entityPascal}ById(this.id);

  @override
  List<Object?> get props => [id];
}

class Search$featurePascal extends ${entityPascal}Event {
  final String query;

  const Search$featurePascal(this.query);

  @override
  List<Object?> get props => [query];
}

class Create$entityPascal extends ${entityPascal}Event {
  final ${entityPascal}Entity entity;

  const Create$entityPascal(this.entity);

  @override
  List<Object?> get props => [entity];
}

class Update$entityPascal extends ${entityPascal}Event {
  final ${entityPascal}Entity entity;

  const Update$entityPascal(this.entity);

  @override
  List<Object?> get props => [entity];
}

class Delete$entityPascal extends ${entityPascal}Event {
  final int id;

  const Delete$entityPascal(this.id);

  @override
  List<Object?> get props => [id];
}

class SyncPending$featurePascal extends ${entityPascal}Event {
  const SyncPending$featurePascal();
}
''';

  String get _stateTemplate => '''
import 'package:equatable/equatable.dart';
import 'package:$packageName/features/$featureName/domain/entities/$entitySingular.dart';

abstract class ${entityPascal}State extends Equatable {
  const ${entityPascal}State();

  @override
  List<Object?> get props => [];
}

class ${entityPascal}Initial extends ${entityPascal}State {
  const ${entityPascal}Initial();
}

class ${entityPascal}Loading extends ${entityPascal}State {
  const ${entityPascal}Loading();
}

class ${entityPascal}Loaded extends ${entityPascal}State {
  final List<${entityPascal}Entity> entities;

  const ${entityPascal}Loaded({required this.entities});

  @override
  List<Object?> get props => [entities];
}

class ${entityPascal}DetailLoaded extends ${entityPascal}State {
  final ${entityPascal}Entity entity;

  const ${entityPascal}DetailLoaded({required this.entity});

  @override
  List<Object?> get props => [entity];
}

class ${entityPascal}OperationSuccess extends ${entityPascal}State {
  final String message;

  const ${entityPascal}OperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class ${entityPascal}Error extends ${entityPascal}State {
  final String message;

  const ${entityPascal}Error({required this.message});

  @override
  List<Object?> get props => [message];
}
''';

  String get _blocTemplate => '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:$packageName/features/$featureName/domain/usecases/get_all_${entitySingular}_usecase.dart';
import 'package:$packageName/features/$featureName/domain/usecases/get_by_${parentEntity}_id_${entitySingular}_usecase.dart';
import 'package:$packageName/features/$featureName/domain/usecases/get_by_id_${entitySingular}_usecase.dart';
import 'package:$packageName/features/$featureName/domain/usecases/search_${entitySingular}_usecase.dart';
import 'package:$packageName/features/$featureName/domain/usecases/create_${entitySingular}_usecase.dart';
import 'package:$packageName/features/$featureName/domain/usecases/update_${entitySingular}_usecase.dart';
import 'package:$packageName/features/$featureName/domain/usecases/delete_${entitySingular}_usecase.dart';
import 'package:$packageName/features/$featureName/domain/usecases/sync_pending_${entitySingular}_usecase.dart';
import 'package:$packageName/features/$featureName/domain/usecases/no_params.dart';
import '${entitySingular}_event.dart';
import '${entitySingular}_state.dart';

@injectable
class ${entityPascal}Bloc extends Bloc<${entityPascal}Event, ${entityPascal}State> {
  final GetAll${entityPascal}UseCase getAllUseCase;
  final GetBy${parentPascal}Id${entityPascal}UseCase getBy${parentPascal}IdUseCase;
  final GetById${entityPascal}UseCase getByIdUseCase;
  final Search${entityPascal}UseCase searchUseCase;
  final Create${entityPascal}UseCase createUseCase;
  final Update${entityPascal}UseCase updateUseCase;
  final Delete${entityPascal}UseCase deleteUseCase;
  final SyncPending${entityPascal}UseCase syncPendingUseCase;

  ${entityPascal}Bloc(
    this.getAllUseCase,
    this.getBy${parentPascal}IdUseCase,
    this.getByIdUseCase,
    this.searchUseCase,
    this.createUseCase,
    this.updateUseCase,
    this.deleteUseCase,
    this.syncPendingUseCase,
  ) : super(const ${entityPascal}Initial()) {
    on<LoadAll$featurePascal>(_onLoadAll);
    on<Load${featurePascal}By${parentPascal}Id>(_onLoadBy${parentPascal}Id);
    on<Load${entityPascal}ById>(_onLoadById);
    on<Search$featurePascal>(_onSearch);
    on<Create$entityPascal>(_onCreate);
    on<Update$entityPascal>(_onUpdate);
    on<Delete$entityPascal>(_onDelete);
    on<SyncPending$featurePascal>(_onSyncPending);
  }

  Future<void> _onLoadAll(
    LoadAll$featurePascal event,
    Emitter<${entityPascal}State> emit,
  ) async {
    emit(const ${entityPascal}Loading());
    final result = await getAllUseCase(const NoParams());
    result.fold(
      (failure) => emit(${entityPascal}Error(message: failure.message)),
      (entities) => emit(${entityPascal}Loaded(entities: entities)),
    );
  }

  Future<void> _onLoadBy${parentPascal}Id(
    Load${featurePascal}By${parentPascal}Id event,
    Emitter<${entityPascal}State> emit,
  ) async {
    emit(const ${entityPascal}Loading());
    final result = await getBy${parentPascal}IdUseCase(event.${parentCamel}Id);
    result.fold(
      (failure) => emit(${entityPascal}Error(message: failure.message)),
      (entities) => emit(${entityPascal}Loaded(entities: entities)),
    );
  }

  Future<void> _onLoadById(
    Load${entityPascal}ById event,
    Emitter<${entityPascal}State> emit,
  ) async {
    emit(const ${entityPascal}Loading());
    final result = await getByIdUseCase(event.id);
    result.fold(
      (failure) => emit(${entityPascal}Error(message: failure.message)),
      (entity) {
        if (entity != null) {
          emit(${entityPascal}DetailLoaded(entity: entity));
        } else {
          emit(const ${entityPascal}Error(message: '${entityPascal} not found'));
        }
      },
    );
  }

  Future<void> _onSearch(
    Search$featurePascal event,
    Emitter<${entityPascal}State> emit,
  ) async {
    emit(const ${entityPascal}Loading());
    final result = await searchUseCase(event.query);
    result.fold(
      (failure) => emit(${entityPascal}Error(message: failure.message)),
      (entities) => emit(${entityPascal}Loaded(entities: entities)),
    );
  }

  Future<void> _onCreate(
    Create$entityPascal event,
    Emitter<${entityPascal}State> emit,
  ) async {
    emit(const ${entityPascal}Loading());
    final result = await createUseCase(event.entity);
    result.fold(
      (failure) => emit(${entityPascal}Error(message: failure.message)),
      (id) => emit(const ${entityPascal}OperationSuccess(message: '${entityPascal} created successfully')),
    );
  }

  Future<void> _onUpdate(
    Update$entityPascal event,
    Emitter<${entityPascal}State> emit,
  ) async {
    emit(const ${entityPascal}Loading());
    final result = await updateUseCase(event.entity);
    result.fold(
      (failure) => emit(${entityPascal}Error(message: failure.message)),
      (_) => emit(const ${entityPascal}OperationSuccess(message: '${entityPascal} updated successfully')),
    );
  }

  Future<void> _onDelete(
    Delete$entityPascal event,
    Emitter<${entityPascal}State> emit,
  ) async {
    emit(const ${entityPascal}Loading());
    final result = await deleteUseCase(event.id);
    result.fold(
      (failure) => emit(${entityPascal}Error(message: failure.message)),
      (_) => emit(const ${entityPascal}OperationSuccess(message: '${entityPascal} deleted successfully')),
    );
  }

  Future<void> _onSyncPending(
    SyncPending$featurePascal event,
    Emitter<${entityPascal}State> emit,
  ) async {
    final result = await syncPendingUseCase(const NoParams());
    result.fold(
      (failure) => emit(${entityPascal}Error(message: 'Sync failed: \${failure.message}')),
      (_) => emit(const ${entityPascal}OperationSuccess(message: 'Synced successfully')),
    );
  }
}
''';

  String get _listPageTemplate => '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$packageName/core/di/injection.dart';
import 'package:$packageName/features/$featureName/domain/entities/$entitySingular.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${entitySingular}_bloc.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${entitySingular}_event.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${entitySingular}_state.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${entitySingular}_detail_page.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${entitySingular}_form_page.dart';
import 'package:intl/intl.dart';

class ${entityPascal}ListPage extends StatelessWidget {
  final int? ${parentCamel}Id;

  const ${entityPascal}ListPage({super.key, this.${parentCamel}Id});

  void _loadData(BuildContext context) {
    context.read<${entityPascal}Bloc>().add(
      ${parentCamel}Id != null
          ? Load${featurePascal}By${parentPascal}Id(${parentCamel}Id!)
          : const LoadAll${featurePascal}(),
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    _loadData(context);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$featurePascal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              context.read<${entityPascal}Bloc>().add(const SyncPending$featurePascal());
            },
          ),
        ],
      ),
      body: BlocProvider(
        create: (context) => getIt<${entityPascal}Bloc>()
          ..add(
            ${parentCamel}Id != null
                ? Load${featurePascal}By${parentPascal}Id(${parentCamel}Id!)
                : const LoadAll${featurePascal}(),
          ),
        child: BlocConsumer<${entityPascal}Bloc, ${entityPascal}State>(
          listener: (context, state) {
            if (state is ${entityPascal}Error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            } else if (state is ${entityPascal}OperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
              _loadData(context);
            }
          },
          builder: (context, state) {
            if (state is ${entityPascal}Loading) {
              return const Center(child: CircularProgressIndicator());
            }

            List<${entityPascal}Entity> entities = [];
            if (state is ${entityPascal}Loaded) {
              entities = state.entities;
            }

            if (entities.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _handleRefresh(context),
                child: ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No items found'),
                            SizedBox(height: 8),
                            Text('Pull down to refresh', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _handleRefresh(context),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entities.length,
                itemBuilder: (context, index) {
                  final entity = entities[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${entityPascal} #\${entity.id}'),
                      subtitle: Text('Created: \${DateFormat.yMMMd().format(entity.createdAt)}'),
                      trailing: _buildSyncStatusIcon(entity.syncStatus),
                      onTap: () async {
                        final bloc = context.read<${entityPascal}Bloc>();
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ${entityPascal}DetailPage(entity: entity),
                          ),
                        );
                        if (updated == true) {
                          bloc.add(
                            ${parentCamel}Id != null
                                ? Load${featurePascal}By${parentPascal}Id(${parentCamel}Id!)
                                : const LoadAll${featurePascal}(),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: ${parentCamel}Id != null
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ${entityPascal}FormPage(${parentCamel}Id: ${parentCamel}Id!),
                  ),
                );
                if (created == true && context.mounted) {
                  context.read<${entityPascal}Bloc>().add(Load${featurePascal}By${parentPascal}Id(${parentCamel}Id!));
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSyncStatusIcon(String status) {
    switch (status) {
      case 'synced':
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case 'pending':
        return const Icon(Icons.pending, color: Colors.orange, size: 20);
      case 'failed':
        return const Icon(Icons.error, color: Colors.red, size: 20);
      default:
        return const Icon(Icons.help, color: Colors.grey, size: 20);
    }
  }
}
''';

  String get _detailPageTemplate => '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$packageName/core/di/injection.dart';
import 'package:$packageName/features/$featureName/domain/entities/$entitySingular.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${entitySingular}_bloc.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${entitySingular}_event.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${entitySingular}_state.dart';
import 'package:$packageName/features/$featureName/presentation/pages/${entitySingular}_form_page.dart';
import 'package:intl/intl.dart';

class ${entityPascal}DetailPage extends StatelessWidget {
  final ${entityPascal}Entity entity;

  const ${entityPascal}DetailPage({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<${entityPascal}Bloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${entityPascal} Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ${entityPascal}FormPage(
                      ${parentCamel}Id: entity.${parentCamel}Id,
                      entity: entity,
                    ),
                  ),
                );
                if (updated == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(context),
              const SizedBox(height: 16),
              _buildDetailsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${entityPascal} #\${entity.id}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Created: \${DateFormat.yMMMd().add_jm().format(entity.createdAt)}'),
            if (entity.updatedAt != null) ...[
              const SizedBox(height: 4),
              Text('Updated: \${DateFormat.yMMMd().add_jm().format(entity.updatedAt!)}'),
            ],
            const SizedBox(height: 4),
            _buildSyncStatusChip(entity.syncStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow('ID', entity.id.toString()),
            _buildDetailRow('${parentPascal} ID', entity.${parentCamel}Id.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSyncStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'synced':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete ${entityPascal}'),
        content: const Text('Are you sure you want to delete this ${entitySingular}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<${entityPascal}Bloc>().add(Delete$entityPascal(entity.id));
              Navigator.pop(dialogContext);
              Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
''';

  String get _formPageTemplate => '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$packageName/core/di/injection.dart';
import 'package:$packageName/features/$featureName/domain/entities/$entitySingular.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${entitySingular}_bloc.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${entitySingular}_event.dart';
import 'package:$packageName/features/$featureName/presentation/bloc/${entitySingular}_state.dart';

class ${entityPascal}FormPage extends StatefulWidget {
  final int ${parentCamel}Id;
  final ${entityPascal}Entity? entity;

  const ${entityPascal}FormPage({
    super.key,
    required this.${parentCamel}Id,
    this.entity,
  });

  @override
  State<${entityPascal}FormPage> createState() => _${entityPascal}FormPageState();
}

class _${entityPascal}FormPageState extends State<${entityPascal}FormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // TODO: Add form controllers for your custom fields

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.entity != null) {
      // TODO: Initialize controllers with entity values
    }
  }

  @override
  void dispose() {
    // TODO: Dispose controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entity != null;

    return BlocProvider(
      create: (context) => getIt<${entityPascal}Bloc>(),
      child: BlocConsumer<${entityPascal}Bloc, ${entityPascal}State>(
        listener: (context, state) {
          if (state is ${entityPascal}Error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
            setState(() => _isLoading = false);
          } else if (state is ${entityPascal}OperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context, true);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(isEdit ? 'Edit ${entityPascal}' : 'New ${entityPascal}'),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildFormFields(),
                  const SizedBox(height: 24),
                  _buildActionButtons(isEdit, context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Information', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            const SizedBox(height: 16),
            const Text('TODO: Add form fields for your entity properties', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isEdit, BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _handleSubmit(context, isEdit),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isEdit ? 'Update' : 'Create'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  void _handleSubmit(BuildContext context, bool isEdit) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Create entity from form values
    // Add your custom field values below:
    final entity = ${entityPascal}Entity(
      id: widget.entity?.id ?? 0,
      ${parentCamel}Id: widget.${parentCamel}Id,
// TODO_USER_FIELDS
      syncStatus: 'pending',
      createdAt: widget.entity?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEdit) {
      context.read<${entityPascal}Bloc>().add(Update$entityPascal(entity));
    } else {
      context.read<${entityPascal}Bloc>().add(Create$entityPascal(entity));
    }
  }
}
''';
}
