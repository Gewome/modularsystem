<p>Dear <?php echo e($enrollment->first_name); ?>,</p>
<p>We regret to inform you that your enrollment for <?php echo e($enrollment->program->name ?? 'No Program'); ?> has been <strong>rejected</strong>.</p>
<p>Reason: <?php echo e($reason); ?></p>
<p>If you have questions, please contact us.</p><?php /**PATH C:\Users\gucor\OneDrive\Documents\Herd\Modular_System\resources\views\Emails\enrollment_rejected.blade.php ENDPATH**/ ?>