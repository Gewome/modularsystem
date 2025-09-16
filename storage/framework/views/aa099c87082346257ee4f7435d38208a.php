<p>Dear <?php echo e($enrollment->first_name); ?>,</p>
<p>Your enrollment for <?php echo e($enrollment->program->name ?? 'No Program'); ?> has been <strong>approved</strong>.</p>
<p>Please check your student portal for further details.</p>
<p><strong>Username:</strong> <?php echo e($username); ?></p>
<p><strong>Password:</strong> <?php echo e($password); ?></p>
<p>Thank you for choosing Bohol Northern Star College!</p><?php /**PATH C:\Users\gucor\OneDrive\Documents\Herd\Modular_System\resources\views\Emails\enrollment_approved.blade.php ENDPATH**/ ?>