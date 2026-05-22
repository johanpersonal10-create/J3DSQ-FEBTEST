// Contacts screen — CRM for clients, suppliers, and store contacts

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/alerts.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _filterType = 'todos';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ContactModel> _filtered(List<ContactModel> all) {
    var list = all;
    if (_filterType != 'todos') {
      list = list.where((c) => c.type == _filterType).toList();
    }
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.phone.contains(q) ||
              c.email.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final contacts = _filtered(state.contacts);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Contactos'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar contacto...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Type filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Todos',
                      count: state.contacts.length,
                      selected: _filterType == 'todos',
                      onTap: () => setState(() => _filterType = 'todos'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Clientes',
                      icon: Icons.person_rounded,
                      count: state.contacts
                          .where((c) => c.type == 'cliente')
                          .length,
                      selected: _filterType == 'cliente',
                      onTap: () => setState(() => _filterType = 'cliente'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Proveed.',
                      icon: Icons.local_shipping_rounded,
                      count: state.contacts
                          .where((c) => c.type == 'proveedor')
                          .length,
                      selected: _filterType == 'proveedor',
                      onTap: () => setState(() => _filterType = 'proveedor'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Tiendas',
                      icon: Icons.store_rounded,
                      count: state.contacts
                          .where((c) => c.type == 'tienda')
                          .length,
                      selected: _filterType == 'tienda',
                      onTap: () => setState(() => _filterType = 'tienda'),
                    ),
                  ],
                ),
              ),

              // Contacts list
              Expanded(
                child: contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.contacts_outlined,
                                size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            const Text(
                              'Sin contactos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Agrega clientes, proveedores o contactos de tiendas',
                              style:
                                  TextStyle(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: contacts.length,
                        itemBuilder: (_, i) =>
                            _ContactCard(contact: contacts[i]),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showContactForm(context),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Nuevo'),
          ),
        );
      },
    );
  }

  void _showContactForm(BuildContext context, {ContactModel? contact}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ContactFormSheet(contact: contact),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13,
                    color: selected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  '$label ($count)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final ContactModel contact;
  const _ContactCard({required this.contact});

  IconData get _typeIcon {
    switch (contact.type) {
      case 'proveedor':
        return Icons.local_shipping_rounded;
      case 'tienda':
        return Icons.store_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color get _typeColor {
    switch (contact.type) {
      case 'proveedor':
        return AppColors.warning;
      case 'tienda':
        return AppColors.primary;
      default:
        return AppColors.success;
    }
  }

  String get _typeLabel {
    switch (contact.type) {
      case 'proveedor':
        return 'Proveedor';
      case 'tienda':
        return 'Tienda';
      default:
        return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _typeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              if (contact.phone.isNotEmpty)
                IconButton(
                  onPressed: () => _makeCall(contact.phone),
                  icon: const Icon(Icons.phone_rounded),
                  color: AppColors.success,
                  iconSize: 20,
                ),
              if (contact.email.isNotEmpty)
                IconButton(
                  onPressed: () => _sendEmail(contact.email),
                  icon: const Icon(Icons.email_rounded),
                  color: AppColors.primary,
                  iconSize: 20,
                ),
              GestureDetector(
                onTap: () => _showActions(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
              ),
            ],
          ),
          if (contact.phone.isNotEmpty || contact.email.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            if (contact.phone.isNotEmpty)
              _InfoRow(
                  icon: Icons.phone_outlined, text: contact.phone),
            if (contact.email.isNotEmpty)
              _InfoRow(
                  icon: Icons.email_outlined, text: contact.email),
            if (contact.address.isNotEmpty)
              _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: contact.address),
          ],
          if (contact.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              contact.notes,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  void _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) =>
                      _ContactFormSheet(contact: contact),
                );
              },
            ),
            if (contact.phone.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.message_rounded,
                    color: AppColors.success),
                title: const Text('WhatsApp'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openWhatsApp(contact.phone);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_rounded,
                  color: AppColors.danger),
              title: const Text('Eliminar',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDelete(
      context,
      title: 'Eliminar Contacto',
      message: '¿Eliminar a "${contact.name}"? Esta acción no se puede deshacer.',
    );
    if (confirmed && context.mounted) {
      try {
        await context.read<AppState>().deleteContact(contact.id);
        if (context.mounted) {
          showSuccess(context, '"${contact.name}" eliminado correctamente');
        }
      } catch (e) {
        if (context.mounted) {
          showError(context, 'Error al eliminar: $e');
        }
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Form ───────────────────────────────────────────

class _ContactFormSheet extends StatefulWidget {
  final ContactModel? contact;
  const _ContactFormSheet({this.contact});

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;
  String _type = 'cliente';
  bool _isSaving = false;

  bool get isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.contact?.name ?? '');
    _phoneCtrl =
        TextEditingController(text: widget.contact?.phone ?? '');
    _emailCtrl =
        TextEditingController(text: widget.contact?.email ?? '');
    _addressCtrl =
        TextEditingController(text: widget.contact?.address ?? '');
    _notesCtrl =
        TextEditingController(text: widget.contact?.notes ?? '');
    _type = widget.contact?.type ?? 'cliente';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModalHeader(
                  title: isEditing
                      ? 'Editar Contacto'
                      : 'Nuevo Contacto'),
              const SizedBox(height: 20),

            // Type selector
            const Text('Tipo',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeButton(
                  label: 'Cliente',
                  icon: Icons.person_rounded,
                  selected: _type == 'cliente',
                  onTap: () => setState(() => _type = 'cliente'),
                ),
                const SizedBox(width: 8),
                _TypeButton(
                  label: 'Proveedor',
                  icon: Icons.local_shipping_rounded,
                  selected: _type == 'proveedor',
                  onTap: () => setState(() => _type = 'proveedor'),
                ),
                const SizedBox(width: 8),
                _TypeButton(
                  label: 'Tienda',
                  icon: Icons.store_rounded,
                  selected: _type == 'tienda',
                  onTap: () => setState(() => _type = 'tienda'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('Nombre *',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(hintText: 'Nombre completo'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Teléfono',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            hintText: '+52 55 1234 5678'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            hintText: 'correo@email.com'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('Dirección',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                  hintText: 'Dirección o ubicación'),
            ),
            const SizedBox(height: 16),

            const Text('Notas',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Notas adicionales...',
              ),
            ),
            const SizedBox(height: 24),

            LoadingButton(
              isLoading: _isSaving,
              onPressed: _handleSave,
              label: isEditing
                  ? 'Guardar Cambios'
                  : 'Crear Contacto',
              icon: isEditing
                  ? Icons.save_rounded
                  : Icons.person_add_rounded,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      ),
    );
  }

  void _handleSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showWarning(context, 'El nombre del contacto es obligatorio');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final state = context.read<AppState>();
      if (isEditing) {
        await state.updateContact(
          widget.contact!.id,
          name: name,
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          type: _type,
        );
      } else {
        await state.addContact(
          name: name,
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
          type: _type,
        );
      }

      if (mounted) {
        FocusScope.of(context).unfocus();
        Navigator.pop(context);
        showSuccess(
          context,
          isEditing
              ? '"$name" actualizado correctamente'
              : '"$name" creado correctamente',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showError(context, 'Error al guardar: $e');
      }
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  selected ? AppColors.primary : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15,
                    color: selected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
